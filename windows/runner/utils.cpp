#include "utils.h"

#include <filesystem>
#include <fstream>
#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::optional<std::wstring> ResolveFalconActiveAotLibraryPath() {
  wchar_t executable_path[MAX_PATH];
  const DWORD length =
      ::GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return std::nullopt;
  }

  const std::filesystem::path install_dir =
      std::filesystem::path(executable_path).parent_path();
  const std::filesystem::path pointer_path =
      install_dir / L".flutter_falcon" / L"active_aot_library_path.txt";
  if (!std::filesystem::exists(pointer_path)) {
    return std::nullopt;
  }

  std::wifstream pointer_file(pointer_path);
  if (!pointer_file.is_open()) {
    return std::nullopt;
  }

  std::wstring active_path;
  std::getline(pointer_file, active_path);
  while (!active_path.empty() &&
         (active_path.back() == L'\r' || active_path.back() == L'\n' ||
          active_path.back() == L' ' || active_path.back() == L'\t')) {
    active_path.pop_back();
  }
  if (active_path.empty()) {
    return std::nullopt;
  }

  const std::filesystem::path aot_path(active_path);
  if (!std::filesystem::exists(aot_path)) {
    return std::nullopt;
  }
  return aot_path.wstring();
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
