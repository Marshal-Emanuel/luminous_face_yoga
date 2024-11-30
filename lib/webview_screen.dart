import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:luminous_face_yoga/screens/notification_settings.dart';
import 'package:luminous_face_yoga/screens/progress_screen.dart';
import 'package:luminous_face_yoga/services/progress_service.dart';
import 'package:luminous_face_yoga/services/notification_service.dart';
import 'package:luminous_face_yoga/widgets/loading_overlay.dart';
import 'package:luminous_face_yoga/widgets/achievement_unlocked_dialog.dart';
import 'package:luminous_face_yoga/models/achievement_data.dart';
import 'package:flutter/cupertino.dart';

class ProgramTracker {
  final InAppWebViewController controller;
  Timer? _selectionCheckTimer;
  String currentProgramName = '';

  ProgramTracker(this.controller) {
    _initializeTracker();
  }

  void dispose() {
    _selectionCheckTimer?.cancel();
  }

  Future<void> _initializeTracker() async {
    // Inject the tracking script when entering a program page
    controller.addJavaScriptHandler(
      handlerName: 'programSelectionUpdate',
      callback: (args) async {
        if (args.length >= 3) {
          final programName = args[0] as String;
          final week = args[1] as String;
          final day = args[2] as String;
          print('Program: $programName, Week: $week, Day: $day');

          // Log user progress without sending a notification
          await ProgressService.saveProgress(programName, week, day);
        }
      },
    );
  }

  Future<void> injectTrackingScript() async {
    await controller.evaluateJavascript(source: '''
      (function() {
        function getProgramName() {
          const pathParts = window.location.pathname.split('/');
          const programIndex = pathParts.indexOf('programmes');
          if (programIndex !== -1 && pathParts.length > programIndex + 1) {
            return pathParts[programIndex + 1].replace(/-/g, ' ');
          }
          return '';
        }

        function trackVideoSelection() {
          document.querySelectorAll('.single_video').forEach(video => {
            video.addEventListener('click', function(e) {
              const weekElement = this.closest('.single_week');
              const weekNumber = weekElement ? weekElement.querySelector('.number').textContent.trim() : '';
              const dayTextElement = this.querySelector('p');
              const dayText = dayTextElement ? dayTextElement.textContent.trim() : '';
              
              if (weekNumber && dayText) {
                window.flutter_inappwebview.callHandler(
                  'programSelectionUpdate',
                  getProgramName(),
                  weekNumber,
                  dayText
                );
              }
            });
          });
        }

        function checkProgramContent() {
          if (document.querySelector('.single_week')) {
            trackVideoSelection();
            return true;
          }
          return false;
        }

        // Set up a MutationObserver to watch for dynamic content loading
        const observer = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            if (mutation.addedNodes.length) {
              checkProgramContent();
            }
          });
        });

        // Start observing the document body for changes
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });

        // Initial check
        if (!checkProgramContent()) {
          const contentCheckInterval = setInterval(() => {
            if (checkProgramContent()) {
              clearInterval(contentCheckInterval);
            }
          }, 500);

          // Clear interval after 10 seconds to prevent infinite checking
          setTimeout(() => clearInterval(contentCheckInterval), 10000);
        }
      })();
    ''');
  }

  Future<void> checkForProgramPage(String url) async {
    if (url.contains('/programmes/') && url.split('/').length > 4) {
      // Wait for the page to load
      await Future.delayed(Duration(milliseconds: 500));
      await injectTrackingScript();

      // Extract program name from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length > 1 && pathSegments[0] == 'programmes') {
        currentProgramName = pathSegments[1].replaceAll('-', ' ');
      }
    }
  }
}

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({Key? key}) : super(key: key);

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  InAppWebViewController? webViewController;
  ProgramTracker? programTracker;
  PullToRefreshController? _refreshController;
  bool isLoading = true;
  Timer? _loadingTimer;
  String _selectedDay = "";
  String _selectedWeek = "";
  bool _welcomeUnlocked = false;
  String _previousUrl = '';
  bool _isDisposed = false;
  bool canGoBack = false;

  // URLs
  final String initialUrl = "https://www.luminousfaceyoga.com/login/";
  final String loginUrl = 'https://www.luminousfaceyoga.com/login/';
  final String homeUrl = 'https://www.luminousfaceyoga.com/';

  // UserScripts
  final UserScript footerHidingScript = UserScript(
    source: '''
      (function() {
        function hideFooter() {
          var footer = document.querySelector('footer.elementor-location-footer');
          if (footer) {
            footer.style.display = 'none';
          }
        }

        function onBodyAvailable(callback) {
          if (document.body) {
            callback();
          } else {
            document.addEventListener('DOMContentLoaded', callback);
          }
        }

        onBodyAvailable(function() {
          hideFooter();
          var observer = new MutationObserver(hideFooter);
          observer.observe(document.body, { childList: true, subtree: true });
        });
      })();
    ''',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  late final UserScript headerHidingScript = UserScript(
    source: '''
      (function() {
        function hideHeader() {
          if (window.location.href.includes('$loginUrl')) {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = 'header.elementor-location-header { display: none !important; }';
            document.head?.appendChild(style);
          }
        }

        function hidePopup() {
            var popup = document.querySelector('#elementor-popup-modal-19147');
          if (popup) popup.style.display = 'none';
        }

        function onDomReady(callback) {
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', callback);
          } else {
            callback();
          }
        }

        onDomReady(function() {
          hideHeader();
          hidePopup();
          
          const observer = new MutationObserver(function() {
            hideHeader();
            hidePopup();
          });
          
          observer.observe(document.body, { childList: true, subtree: true });
        });
      })();
    ''',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  Future<void> injectSelectionTrackingScript() async {
    if (webViewController == null) return;

    await webViewController?.evaluateJavascript(source: '''
      (function() {
        function findActiveElement(selector, attribute) {
          const elements = document.querySelectorAll(selector);
          for (const element of elements) {
            if (element.getAttribute(attribute) === 'true' || element.classList.contains('active')) {
              return element.textContent.trim();
            }
          }
          return null;
        }

        function getSelections() {
          const weekSelectors = [
            '.number.active',
            '.week-selector.active',
            '.week-item[data-active="true"]',
            '.week-tab.selected',
            '.programme-week.active'
          ];
          
          const daySelectors = [
            '.days.active',
            '.day-selector.active',
            '.day-item[data-active="true"]',
            '.day-tab.selected',
            '.programme-day.active'
          ];
          
          let week = null;
          let day = null;
          
          for (const selector of weekSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              week = element.textContent.trim();
              break;
            }
          }
          
          for (const selector of daySelectors) {
            const element = document.querySelector(selector);
            if (element) {
              day = element.textContent.trim();
              break;
            }
          }

          if (!week || !day) {
            week = week || findActiveElement('[data-week]', 'data-active');
            day = day || findActiveElement('[data-day]', 'data-active');
          }
          
          if (week || day) {
            window.flutter_inappwebview.callHandler(
              'updateSelection',
              week || 'Week Unknown',
              day || 'Day Unknown'
            );
            console.log('Selection updated:', { week, day });
          }
        }

        function setupSelectionMonitoring() {
          getSelections();
          
          const observer = new MutationObserver((mutations) => {
            for (const mutation of mutations) {
              if (mutation.type === 'attributes' || mutation.type === 'childList') {
                getSelections();
              }
            }
          });

          if (document.body) {
            observer.observe(document.body, {
              attributes: true,
              childList: true,
              subtree: true,
              attributeFilter: ['class', 'data-active']
            });
          }
        }

        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', setupSelectionMonitoring);
        } else {
          setupSelectionMonitoring();
        }
        
        window.addEventListener('load', getSelections);
        window.addEventListener('popstate', getSelections);
      })();
    ''');
  }

  @override
  void initState() {
    super.initState();
    _initializePullToRefresh();
    startLoadingTimer();
  }

  void _initializePullToRefresh() {
    _refreshController = PullToRefreshController(
      onRefresh: () {
        if (!_isDisposed && webViewController != null) {
          webViewController?.reload();
        }
      },
      options: PullToRefreshOptions(
        color: Colors.white,
        backgroundColor: Colors.blue,
      ),
    );
  }

  void startLoadingTimer() {
    _loadingTimer?.cancel();
    if (!_isDisposed) {
      setState(() {
        isLoading = true;
      });

      _loadingTimer = Timer(const Duration(seconds: 2), () {
        if (!_isDisposed && mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  void _endRefreshing() {
    if (_refreshController != null) {
      _refreshController!.endRefreshing();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadingTimer?.cancel();
    if (_refreshController != null) {
      _refreshController!.dispose();
      _refreshController = null;
    }
    webViewController?.dispose();
    programTracker?.dispose();
    super.dispose();
  }

  Future<void> checkForQuizCompletion(String url) async {
    if (!url.contains('quiz/?show=results#gf_2')) return;

    await Future.delayed(Duration(milliseconds: 250));

    final String pageContent =
        await webViewController?.evaluateJavascript(source: """
      (function() {
        const thankText = document.body.textContent || '';
        const hasThankYou = thankText.includes('Thanks! Now check your inbox');
        const hasForm = document.querySelector('.gform_confirmation_wrapper') !== null;
        return JSON.stringify({ hasThankYou, hasForm });
      })()
    """) ?? '{}';

    final Map<String, dynamic> result = jsonDecode(pageContent);

    if (result['hasThankYou'] == true || result['hasForm'] == true) {
      try {
        await ProgressService.unlockQuizAchievement();

        final unlockedAchievement = achievementsList.firstWhere(
          (achievement) => achievement.id == 'first_quiz',
        );

        if (mounted) {
          setState(() {});
          showDialog(
            context: context,
            builder: (context) => AchievementUnlockedDialog(
              achievement: unlockedAchievement,
            ),
          );
        }

        await NotificationService.sendQuizCompletionNotification();
      } catch (e) {
        print('Error handling quiz completion: $e');
      }
    }
  }

  Future<void> _handleUrlChange(String currentUrl) async {
    Uri prevUri = Uri.parse(_previousUrl);
    Uri currUri = Uri.parse(currentUrl);

    bool isLoginTransition = !_welcomeUnlocked &&
        prevUri.path.contains('/login') &&
        currUri.path.contains('/members-area');

    if (isLoginTransition) {
      try {
        await ProgressService.unlockAchievement('first_login');
        setState(() {
          _welcomeUnlocked = true;
        });

        final unlockedAchievement = achievementsList.firstWhere(
          (achievement) => achievement.id == 'first_login',
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AchievementUnlockedDialog(
              achievement: unlockedAchievement,
            ),
          );
        }
      } catch (e) {
        print('Error unlocking login achievement: $e');
      }
    }

    // Do not log progress or send notifications here
    // Progress is logged when the user makes a selection
    _previousUrl = currentUrl;
  }

  Future<bool> _handleBackNavigation(BuildContext context) async {
    if (webViewController != null) {
      if (await webViewController!.canGoBack()) {
        await webViewController!.goBack();
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: canGoBack ? AppBar(
        backgroundColor: const Color(0xFF18314F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            if (await webViewController?.canGoBack() ?? false) {
              webViewController?.goBack();
            }
          },
        ),
      ) : null,
      floatingActionButton: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: 'progress_button',
                onPressed: () => _handleNavigation('/progress'),
                backgroundColor: const Color(0xFF66D7D1),
                child: const Icon(Icons.insights, color: Colors.white),
              ),
            ),
            FloatingActionButton(
              heroTag: 'notification_button',
              onPressed: () => _handleNavigation('/settings'),
              backgroundColor: const Color(0xFFE99C83),
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
      body: WillPopScope(
        onWillPop: () => _handleBackNavigation(context),
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(initialUrl),
              ),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                ),
                ios: IOSInAppWebViewOptions(
                  allowsBackForwardNavigationGestures: true, // Enable iOS swipe navigation
                )
              ),
              pullToRefreshController: _refreshController,
              initialUserScripts: UnmodifiableListView<UserScript>([
                footerHidingScript,
                headerHidingScript,
              ]),
              onWebViewCreated: (controller) {
                if (!_isDisposed) {
                  webViewController = controller;
                  programTracker = ProgramTracker(controller);
                  _setupJavaScriptHandlers(controller);
                }
              },
              onLoadStart: (controller, url) {
                if (!_isDisposed) {
                  startLoadingTimer();
                }
              },
              onLoadStop: (controller, url) async {
                if (_isDisposed) return;
                
                _endRefreshing();
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }

                final currentUrl = url.toString();
                await _handlePageLoad(currentUrl);
                _updateNavigationState();
              },
              onProgressChanged: (controller, progress) {
                if (_isDisposed) return;
                
                if (progress == 100) {
                  _endRefreshing();
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
                _updateNavigationState();
              },
            ),
            if (isLoading) LoadingOverlay(),
          ],
        ),
      ),
    );
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'updateSelection',
      callback: (args) {
        if (_isDisposed || args.length < 2) return;
        
        setState(() {
          _selectedWeek = args[0]?.toString() ?? "";
          _selectedDay = args[1]?.toString() ?? "";
        });
        print('Selection updated - Week: $_selectedWeek, Day: $_selectedDay');
      },
    );
  }

  Future<void> _handlePageLoad(String currentUrl) async {
    await injectSelectionTrackingScript();
    await _handleUrlChange(currentUrl);
    await checkForQuizCompletion(currentUrl);

    if (currentUrl.contains('https://www.luminousfaceyoga.com/programmes/') &&
        currentUrl.split('/').length > 4) {
      await _handleProgramPage(currentUrl);
    }
  }

  Future<void> _handleProgramPage(String currentUrl) async {
    String programName = currentUrl.split('/')[4].replaceAll('-', ' ');
    Map<String, String>? lastProgress =
        await ProgressService.getLastProgressForProgram(programName);

    if (lastProgress != null) {
      String week = lastProgress['week'] ?? 'Week Unknown';
      String day = lastProgress['day'] ?? 'Day Unknown';
      await NotificationService.sendNotification(programName, week, day);
    }

    await programTracker?.checkForProgramPage(currentUrl);
  }

  Future<bool> _goBack(BuildContext context) async {
    if (webViewController != null) {
      bool canGoBack = await webViewController!.canGoBack();
      if (canGoBack) {
        webViewController!.goBack();
        return false;
      }
    }
    return true;
  }

  void _handleNavigation(String route) {
    if (!mounted) return;
    
    if (Platform.isIOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) {
            switch (route) {
              case '/progress':
                return const ProgressScreen();
              case '/settings':
                return NotificationSettings();
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      );
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  void _updateNavigationState() async {
    if (webViewController != null) {
      bool back = await webViewController!.canGoBack();
      if (mounted) {
        setState(() => canGoBack = back);
      }
    }
  }
}
