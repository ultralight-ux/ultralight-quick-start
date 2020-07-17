#pragma once
#include <AppCore/AppCore.h>

using namespace ultralight;

class MyApp : public AppListener,
              public WindowListener,
              public LoadListener {
public:
  MyApp();

  virtual ~MyApp();

  // Start the run loop.
  virtual void Run();

  // This is called continuously from the app's main loop. Update logic here.
  virtual void OnUpdate() override;

  // This is called when the window is closing.
  virtual void OnClose() override;

  // This is called whenever the window resizes.
  virtual void OnResize(uint32_t width, uint32_t height) override;

  // This is called when the page finishes a load in the main frame.
  virtual void OnFinishLoading(ultralight::View* caller,
                               uint64_t frame_id,
                               bool is_main_frame,
                               const String& url) override;

  // This is called when the DOM has loaded in the main frame. Update JS here.
  virtual void OnDOMReady(ultralight::View* caller,
                          uint64_t frame_id,
                          bool is_main_frame,
                          const String& url) override;

protected:
  RefPtr<App> app_;
  RefPtr<Window> window_;
  RefPtr<Overlay> overlay_;
};
