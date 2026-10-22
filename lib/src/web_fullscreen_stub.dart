bool get browserFullscreenSupported => true;
void requestBrowserFullscreen() {}
void exitBrowserFullscreen() {}
bool get browserInFullscreen => false;
void addBrowserFullscreenChangeListener(void Function() callback) {}
void removeBrowserFullscreenChangeListener(void Function() callback) {}
void enterVideoElementFullscreen(int playerId, void Function() onExited) {}
void exitVideoElementFullscreen(int playerId) {}
void disposeVideoElementFullscreen(int playerId) {}
