#include "multi_window_child_chrome.h"

#include <dwmapi.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

namespace {

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr COLORREF kChildWindowBackground = RGB(0x1E, 0x1E, 0x1E);
constexpr UINT_PTR kMultiWindowChromeSubclassId = 1;

HBRUSH ChildWindowBackgroundBrush() {
  static HBRUSH brush = CreateSolidBrush(kChildWindowBackground);
  return brush;
}

void ResizeFlutterViewChild(HWND hwnd) {
  HWND child = GetWindow(hwnd, GW_CHILD);
  if (child == nullptr) {
    return;
  }

  RECT rect;
  GetClientRect(hwnd, &rect);
  const int width = rect.right - rect.left;
  const int height = rect.bottom - rect.top;
  if (width <= 0 || height <= 0) {
    return;
  }

  // desktop_multi_window uses MoveWindow(..., TRUE), which repaints the parent
  // GDI surface on every sizing step. That parent still uses COLOR_WINDOW, so
  // each step flashes before Flutter catches up. The main runner window avoids
  // this with hbrBackground = 0 and a single HWND hierarchy.
  SetWindowPos(child, nullptr, 0, 0, width, height,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOMOVE);
}

LRESULT CALLBACK MultiWindowChromeSubclassProc(HWND hwnd,
                                               UINT message,
                                               WPARAM wparam,
                                               LPARAM lparam,
                                               UINT_PTR subclass_id,
                                               DWORD_PTR data) {
  switch (message) {
    case WM_ERASEBKGND:
      if (ChildWindowBackgroundBrush() != nullptr) {
        RECT rect;
        GetClientRect(hwnd, &rect);
        FillRect(reinterpret_cast<HDC>(wparam), &rect,
                 ChildWindowBackgroundBrush());
        return 1;
      }
      break;
    case WM_SIZE: {
      // Let window_manager and desktop_multi_window handle frame + hit-test
      // geometry first. Swallowing WM_SIZE removed the hidden-title-bar resize
      // border that window_manager sets through the normal proc chain.
      const LRESULT result =
          DefSubclassProc(hwnd, message, wparam, lparam);
      ResizeFlutterViewChild(hwnd);
      return result;
    }
    case WM_EXITSIZEMOVE: {
      const LRESULT result =
          DefSubclassProc(hwnd, message, wparam, lparam);
      ResizeFlutterViewChild(hwnd);
      if (HWND child = GetWindow(hwnd, GW_CHILD)) {
        RedrawWindow(child, nullptr, nullptr,
                      RDW_INVALIDATE | RDW_UPDATENOW | RDW_NOERASE);
      }
      return result;
    }
    case WM_DESTROY:
      RemoveWindowSubclass(hwnd, MultiWindowChromeSubclassProc, subclass_id);
      break;
    default:
      break;
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}

}  // namespace

void ConfigureMultiWindowChildChrome(
    flutter::FlutterViewController* controller) {
  if (controller == nullptr || controller->view() == nullptr) {
    return;
  }

  HWND view = controller->view()->GetNativeWindow();
  if (view == nullptr) {
    return;
  }

  HWND hwnd = GetAncestor(view, GA_ROOT);
  if (hwnd == nullptr) {
    hwnd = view;
  }

  BOOL use_dark_mode = TRUE;
  DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &use_dark_mode,
                        sizeof(use_dark_mode));

  SetWindowSubclass(hwnd, MultiWindowChromeSubclassProc,
                    kMultiWindowChromeSubclassId, 0);
}
