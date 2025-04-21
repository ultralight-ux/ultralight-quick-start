# embed_files.py

import os
import sys
import hashlib
import shutil
import platform

def embed_files(folder_paths, out_dir):
    """
    Embeds files from the specified folder paths into a C++ application using the best available method
    for each platform:
      - Windows (MSVC/Clang-CL): Resource files (RC)
      - MacOS / Linux (GCC/Clang): Inline assembly (.incbin)

    Generates a C++ header (EmbeddedFiles.h) and, on Windows, a resource file (data.rc).
    
    The embedded files can be retrieved via the GetEmbeddedFiles() function.

    Args:
        folder_paths (list): List of folder paths containing the files to be embedded.
        out_dir (str): Output directory where the generated files will be stored.
    """
    files_to_embed = []
    output_hash = hashlib.sha256()
    symbol_counter = 0

    for folder_path in folder_paths:
        if folder_path.endswith('/'):
            base_path = folder_path
        else:
            base_path = os.path.dirname(folder_path) + '/'
        for root, _, files in os.walk(folder_path):
            for file in files:
                abs_path = os.path.join(root, file)
                abs_path = abs_path.replace('\\', '/')  # Replace backslashes with forward slashes
                rel_path = os.path.relpath(abs_path, base_path)
                rel_path = rel_path.replace('\\', '/')  # Replace backslashes with forward slashes
                symbol_name = f"FILE_{symbol_counter}"
                files_to_embed.append((abs_path, rel_path, symbol_name))
                output_hash.update(str((abs_path, os.path.getmtime(abs_path))).encode())
                symbol_counter += 1

    output_header = os.path.join(out_dir, "EmbeddedFiles.h")

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    output_hash_hex = output_hash.hexdigest()

    # Check if the hash has changed
    hash_file = os.path.join(out_dir, "output_hash.txt")
    if os.path.exists(hash_file):
        with open(hash_file, "r") as f:
            old_hash = f.read().strip()
        if old_hash == output_hash_hex:
            print("No changes detected in files_to_embed. Skipping file generation.")
            return

    output_header_content = """
    #pragma once
    #include <unordered_map>
    #include <string>
    #include <cstddef>
    #include <cstdint>

    using EmbeddedFilesMap = const std::unordered_map<std::string, std::pair<const uint8_t*, size_t>>;
    """

    if platform.system() == "Windows":
        # Windows: Use resource files (RC)
        rc_file = os.path.join(out_dir, "data.rc")
        rc_content = "#include \"winres.h\"\n"

        for abs_path, rel_path, symbol_name in files_to_embed:
            rc_content += """{symbol_name} RCDATA \"{abs_path}\"\n""".format(symbol_name=symbol_name, abs_path=abs_path)

        with open(rc_file, "w") as f:
            f.write(rc_content)

        output_header_content += """
#include <windows.h>

inline std::pair<const uint8_t*, size_t> GetEmbeddedFileData(const char* resourceName) {
    HRSRC hResource = FindResource(NULL, resourceName, RT_RCDATA);
    if (hResource) {
        HGLOBAL hData = LoadResource(NULL, hResource);
        if (hData) {
            const uint8_t* data = static_cast<const uint8_t*>(LockResource(hData));
            size_t size = SizeofResource(NULL, hResource);
            return std::make_pair(data, size);
        }
    }
    return std::make_pair(nullptr, 0);
}
        """

        output_header_content += """
inline EmbeddedFilesMap& GetEmbeddedFiles() {
    static EmbeddedFilesMap embedded_files = {
        """

        for _, rel_path, symbol_name in files_to_embed:
            output_header_content += """
        {{ "{rel_path}", GetEmbeddedFileData("{symbol_name}") }},""".format(rel_path=rel_path, symbol_name=symbol_name)

        output_header_content += """
    };

    return embedded_files;
}
        """
    else:
        # MacOS / Linux: Use inline assembly (.incbin)
        section = "__TEXT,__const" if platform.system() == "Darwin" else ".rodata,\\\"a\\\",@progbits"
        for abs_path, rel_path, symbol_name in files_to_embed:
            output_header_content += """
    __asm__(".section {section}");
    __asm__(".balign 16");
    __asm__(".globl __binary_{symbol_name}_start");
    __asm__("__binary_{symbol_name}_start:");
    __asm__(".incbin \\"{abs_path}\\"");
    __asm__(".globl __binary_{symbol_name}_end");
    __asm__("__binary_{symbol_name}_end:");
    extern const uint8_t __binary_{symbol_name}_start[] __asm__("__binary_{symbol_name}_start") __attribute__((aligned(16)));
    extern const uint8_t __binary_{symbol_name}_end[] __asm__("__binary_{symbol_name}_end") __attribute__((aligned(16)));
            """.format(section=section, symbol_name=symbol_name, abs_path=abs_path)

        output_header_content += """
    inline EmbeddedFilesMap& GetEmbeddedFiles() {
        static EmbeddedFilesMap embedded_files = {
        """

        for _, rel_path, symbol_name in files_to_embed:
            output_header_content += """
            {{ "{rel_path}", {{ __binary_{symbol_name}_start, static_cast<size_t>(__binary_{symbol_name}_end - __binary_{symbol_name}_start) }} }},""".format(rel_path=rel_path, symbol_name=symbol_name)

        output_header_content += """
        };
        return embedded_files;
    }
        """

    with open(output_header, "w") as f:
        f.write(output_header_content)

    # Write the updated hash to the hash file
    with open(hash_file, "w") as f:
        f.write(output_hash_hex)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python2 embed_files.py <folder_path_1> [<folder_path_2> ...] <output_directory>")
        sys.exit(1)

    folder_paths = sys.argv[1:-1]
    out_dir = sys.argv[-1]
    embed_files(folder_paths, out_dir)