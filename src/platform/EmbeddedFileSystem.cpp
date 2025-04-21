#include "EmbeddedFileSystem.h"
#include "EmbeddedFiles.h"
#include <Ultralight/Buffer.h>
#include <Ultralight/String.h>
#include <Ultralight/platform/FileSystem.h>
#include <Ultralight/platform/Platform.h>

static const char* FileExtensionToMimeType(const char* ext);

namespace ultralight {

inline static std::string ToString(const String& str)
{
    return std::string(str.utf8().data(), str.utf8().length());
}

EmbeddedFileSystem::EmbeddedFileSystem()
{
}

bool EmbeddedFileSystem::FileExists(const String& file_path)
{
    auto& embedded_files = GetEmbeddedFiles();
    return embedded_files.find(ToString(file_path)) != embedded_files.end();
}

String EmbeddedFileSystem::GetFileMimeType(const String& file_path)
{
    std::string file_path_utf8 = ToString(file_path);
    size_t last_dot_pos = file_path_utf8.rfind('.');
    std::string ext = (last_dot_pos != std::string::npos) ? file_path_utf8.substr(last_dot_pos + 1) : "";

	return String(FileExtensionToMimeType(ext.c_str()));
}

String EmbeddedFileSystem::GetFileCharset(const String& file_path)
{
    return "utf-8";
}

RefPtr<Buffer> EmbeddedFileSystem::OpenFile(const String& file_path)
{
    auto& embedded_files = GetEmbeddedFiles();
	auto it = embedded_files.find(ToString(file_path));
    if (it != embedded_files.end()) {
		return Buffer::Create((void*)it->second.first, it->second.second, nullptr, nullptr);
	}

	return nullptr;
}

}  // namespace ultralight

const char* FileExtensionToMimeType(const char* ext)
{
    static const std::unordered_map<std::string, const char*> mime_types = {
        { "html", "text/html" },
        { "htm", "text/html" },
        { "css", "text/css" },
        { "js", "application/javascript" },
        { "json", "application/json" },
        { "jpg", "image/jpeg" },
        { "jpeg", "image/jpeg" },
        { "png", "image/png" },
        { "gif", "image/gif" },
        { "webp", "image/webp" },
        { "svg", "image/svg+xml" },
        { "ico", "image/x-icon" },
        { "txt", "text/plain" },
        { "csv", "text/csv" },
        { "xml", "text/xml" },
        { "pdf", "application/pdf" },
        { "doc", "application/msword" },
        { "docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" },
        { "ppt", "application/vnd.ms-powerpoint" },
        { "pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation" },
        { "xls", "application/vnd.ms-excel" },
        { "xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" },
        { "mp3", "audio/mpeg" },
        { "wav", "audio/wav" },
        { "mp4", "video/mp4" },
        { "avi", "video/x-msvideo" },
        { "mov", "video/quicktime" },
        { "flv", "video/x-flv" },
        { "webm", "video/webm" },
        { "zip", "application/zip" },
        { "rar", "application/x-rar-compressed" },
        { "7z", "application/x-7z-compressed" },
        { "tar", "application/x-tar" },
        { "gz", "application/gzip" },
        { "mpg", "video/mpeg" },
        { "mpeg", "video/mpeg" },
        { "ogg", "application/ogg" },
        { "ogv", "video/ogg" },
        { "oga", "audio/ogg" },
        { "otf", "font/otf" },
        { "ttf", "font/ttf" },
        { "woff", "font/woff" },
        { "woff2", "font/woff2" },
        { "eot", "application/vnd.ms-fontobject" },
        { "sfnt", "font/sfnt" },
        { "bin", "application/octet-stream" },
        { "exe", "application/octet-stream" },
        { "dll", "application/octet-stream" },
        { "psd", "image/vnd.adobe.photoshop" },
        { "ai", "application/postscript" },
        { "eps", "application/postscript" },
        { "ps", "application/postscript" },
        { "m4a", "audio/m4a" },
        { "m4v", "video/x-m4v" },
        { "bmp", "image/bmp" },
        { "tiff", "image/tiff" },
        { "tif", "image/tiff" },
        { "mkv", "video/x-matroska" },
        { "mpa", "video/mpeg" },
        { "mpe", "video/mpeg" },
        { "mid", "audio/midi" },
        { "midi", "audio/midi" },
        { "3gp", "video/3gpp" },
        { "3g2", "video/3gpp2" },
        { "aif", "audio/aiff" },
        { "aiff", "audio/aiff" },
        { "aac", "audio/aac" },
        { "au", "audio/basic" },
        { "wasm", "application/wasm" },
        { "xhtml", "application/xhtml+xml" },
        { "qt", "video/quicktime" }
    };

    auto it = mime_types.find(std::string(ext));
    if (it != mime_types.end()) {
        return it->second;
    }

    return "application/octet-stream"; // default MIME type if not found
}
