#pragma once
#include <Ultralight/platform/FileSystem.h>

namespace ultralight {

///
/// Custom file system implementation that loads files from resources embedded in the executable.
/// 
class EmbeddedFileSystem : public FileSystem {
public:
  EmbeddedFileSystem();

  virtual ~EmbeddedFileSystem() = default;

  virtual bool FileExists(const String& file_path) override;

  virtual String GetFileMimeType(const String& file_path) override;

  virtual String GetFileCharset(const String& file_path) override;

  virtual RefPtr<Buffer> OpenFile(const String& file_path) override;
};

}  // namespace ultralight