// Ionic Starter App

// angular.module is a global place for creating, registering and retrieving Angular modules
// 'starter' is the name of this angular module example (also set in a <body> attribute in index.html)
// the 2nd parameter is an array of 'requires'
// 'starter.controllers' is found in controllers.js
var ionic_start_module = angular.module('starter', ['ionic', 'starter.controllers']);

ionic_start_module.directive('ngFocusInput', ['$timeout', '$parse', function($timeout, $parse) {
    return {
        restrict: 'AE',
        link : function($scope, $element, $attrs) {
            var model = $parse($attrs.ngFocusInput);
            $scope.$watch(model, function(value) {
                if(value === true) {
                    $timeout(function() {
                        $element[0].focus();
                    });
                }
            });
        }
    }
}])

.run(function ($rootScope, $ionicPlatform, $ionicSideMenuDelegate, $ionicHistory, $location, $translate, translationService) {

    $rootScope.serverResponse = function (data) {
        var x2js = new X2JS({attributePrefix : "", keepCData: true});
        return x2js.xml_str2json(data);
    };

    // keyboard locale selector

    window.onresize = function (event) {


    };

    var userLang = navigator.language || navigator.userLanguage;
// if this list is modified, the keyboard name validation in the Connect TenantManager will have to be updated.
// look for string[] s_ValidKeyboadTypes …   in TenantManager.cs

    keyboardLocale = [{ code: '00000409', value: 'en-us' },
                             { code: '00000809', value: 'en-gb' },
                             { code: '040904090C09', value: 'en-au' },
                             { code: '0000041C', value: 'sq' },
                             { code: '00000423', value: 'be' },
                             { code: '0000141A', value: 'bs' },
                             { code: '00010405', value: 'bg' },
                             { code: '00000804', value: 'zh-cn' },
                             { code: '00000404', value: 'zh-tw' },
                             { code: '00000405', value: 'cs' },
                             { code: '00000406', value: 'da' },
                             { code: '00000413', value: 'nl' },
                             { code: '00000425', value: 'et' },
                             { code: '0000040B', value: 'fi' },
                             { code: '0000040C', value: 'fr' },
                             { code: '0000080C', value: 'fr-be' },
                             { code: '00001009', value: 'fr-ca' },
                             { code: '0000100C', value: 'fr-ch' },
                             { code: '00000407', value: 'de' },
                             { code: '00000807', value: 'de-ch' },
                             { code: '00000408', value: 'el' },
                             { code: '0000040D', value: 'he' },
                             { code: '0000040E', value: 'hu' },
                             { code: '0000040F', value: 'is' },
                             { code: '00000410', value: 'it' },
                             { code: 'E0010411', value: 'ja-jp' },
                             { code: 'E0010411', value: 'ja' },
                             { code: 'E0010412', value: 'ko-kr' },
                             { code: 'E0010412', value: 'ko' },
                             { code: 'E0010412', value: 'kr' },
                             { code: '00000426', value: 'lv' },
                             { code: '00010427', value: 'lt' },
                             { code: '00000414', value: 'no' },
                             { code: '00010415', value: 'pl' },
                             { code: '00000816', value: 'pt' },
                             { code: '00010416', value: 'pt-br' },
                             { code: '00000418', value: 'ro' },
                             { code: '00000419', value: 'ru' },
                             { code: '00000C1A', value: 'sr' },
                             { code: '0000041B', value: 'sk' },
                             { code: '00000424', value: 'sl' },
                             { code: '0000040A', value: 'es' },
                             { code: '0001040A', value: 'es-ar' },
                             { code: '0000041D', value: 'sv' },
                             { code: '0000041F', value: 'tr' },
                             { code: '00000422', value: 'uk' },
                             { code: '00000452', value: 'cy' }

    ];

    angular.forEach(keyboardLocale, function (value, key) {

        switch (value.value.toUpperCase()) {
            case "JA":
                value.value = "JA-JP";
                break;
            case "KO":
                value.value = "KO-KR";
                break;
        }

        try {
            $rootScope.keyboardCode = localStorage.getItem('keyboardLocale');
        } catch (err) {
            if (value.value.toUpperCase() == userLang.toUpperCase()) {
                $rootScope.keyboardCode = value.code;
            }
        }
        
    });


    // end keyboard locale selector


  // detect if ClientPortal
  window.isPortal = false;
  // end detection

    var selectedLanguage = localStorage.getItem('lang');

    var localUrl = window.location.href.split("/")[0] + "//" + window.location.href.split("/")[2];

    $rootScope.languages = [];
    translationService.getStringTable({server:localUrl, languageId:''}).then(function(response){
        angular.forEach(response.data.AvailableTranslationLanguages, function(e,i){
            $rootScope.languages.push({
                code:e.LangId,
                name:e.LanguageNameInEnglish + ' (' + e.LanguageNameInLanguage + ')'
            });
        });
        if(!selectedLanguage || !selectedLanguage.length){
            $translate.use(response.data.LanguageId);
            localStorage.setItem('lang', response.data.LanguageId);
        }

        $ionicPlatform.ready(function () {
            // Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
            // for form inputs)
            if (window.cordova && window.cordova.plugins.Keyboard) {
                cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
            }
            if (window.StatusBar) {
                // org.apache.cordova.statusbar required
                StatusBar.styleDefault();
            }

            $rootScope.iframeholder = '';
            $rootScope.configUrl = '';
            $rootScope.iframeHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);

        });

    }, function(){
        if(typeof navigator.globalization !== "undefined") {
            navigator.globalization.getPreferredLanguage(function(language) {//TODO use the getStringTable to get the default language and fallback to this logic
                $translate.use((language.value).split("-")[0]).then(function(data) {
                    console.log("SUCCESS -> " + data);
                }, function(error) {
                    console.log("ERROR -> " + error);
                });
            }, null);
        }
    });



})



.config(function($stateProvider, $urlRouterProvider) {
  $stateProvider

  .state('app', {
    url: "/app",
    abstract: true,
    templateUrl: "templates/menu.html",
    controller: 'AppCtrl'
  })

  .state('login', {
      url: "/login",
      templateUrl: "templates/login.html",
      controller: 'AppCtrl'
    })

  .state('app.dashboard', {
    url: "/dashboard",
    views: {
      'menuContent': {
        templateUrl: "templates/dashboard.html",
        controller: 'DashboardCtrl'
      }
    }
  });
  // if none of the above states are matched, use this as the fallback
  $urlRouterProvider.otherwise('/login');
})

    .factory('translationsLoader', function($q, translationService){
        return function(options){
            var deferred = $q.defer();
            var localUrl = window.location.href.split("/")[0] + "//" + window.location.href.split("/")[2];

            translationService.getStringTable({server:localUrl, languageId:options.key}).then(function(response){
                deferred.resolve(response.data.StringTable);
            }, function(error){//temporary fallback
               deferred.resolve({
                   "username": "Username",
                   "password": "Password",
                   "remember_me": "Remember me",
                   "login": "Connect",
                   "login_noreply": "The login server did not respond. Please verify that you're connected to the network and the server is running.",
                   "radius_auth": "RADIUS Login",
                   "settings": "Settings",
                   "app_view": "List/Grid View",
                   "app_view_list": "List View",
                   "app_view_grid": "Grid View",
                   "mail_to_support": "Mail to support",
                   "login_settings": "Login Settings",
                   "change_network_password": "Change Network Password",
                   "pass_change_success": "The password was successfully changed!",
                   "about": "About",
                   "online_guide": "Online Guide",
                   "where_to_start": "Where to start?",
                   "app_name_text": "EricomÂ® Access Portalâ¢",
                   "version_text": "Version: 7.6.0.0",
                   "copy_text": "Copyright Â© Ericom Software",
                   "details_text": "For more information please visit:",
                   "search": "Search...",
                   "search_results": "Search results",
                   "back": "Back",
                   "connection_list": "Connection List",
                   "applications_list": "My Applications",
                   "favourite_applications": "Favorites",
                   "toggle_favorites": "Toggle Favorites",
                   "add_to_favorites": "Add Favorites",
                   "remove_from_favorites": "Remove Favorites",
                   "connect_to": "Connect to",
                   "open_connection": "Open",
                   "close_connection": "Close",
                   "logout": "Logout",
                   "cat_favorites": "Favorites",
                   "cat_my_apps": "All",
                   "cat_running_apps": "Active",
                   "display_language": "Display Language",
                   "language": "Language",
                   "keyboard_locale": "Keyboard Locale",
                   "select_locale": "Select Keyboard Locale",
                   "select_language": "Select Language",
                   "save_settings": "Save Settings",
                   "save": "Save",
                   "submit": "Submit",
                   "ok": "Ok",
                   "never_show": "Don't show this message again.",
                   "cancel": "Cancel",
                   "app_launch_error": "Application launch error",
                   "active_applications": "Running",
                   "no_published_apps": "No applications published.",
                   "no_favorite_apps": "No favorite applications.",
                   "no_running_apps": "No running applications.",
                   "system_message": "System message",
                   "guide_text": "Welcome to Access Portal. Your applications and desktops are easily available to launch from the left menu bar. Return to the menu bar at any time to switch between sessions or launch other applications and desktops."
               })
            });

            return deferred.promise;
        }
    })

.config(function($stateProvider, $urlRouterProvider, $translateProvider) {

    var selectedLanguage = localStorage.getItem('lang');

    if(null == selectedLanguage || 'string' !== typeof selectedLanguage){
        selectedLanguage = "EN-US";
        switch (navigator.language.toUpperCase()) {
            case "JA":
                selectedLanguage = "JA-JP";
                break;
            case "KO":
                selectedLanguage = "KO-KR";
                break;
        }
    }

    $translateProvider.useLoader('translationsLoader');

    $translateProvider.preferredLanguage(selectedLanguage);

})

/*.run(['$ionicPlatform', '$translate', 'translationService', '$rootScope', function($ionicPlatform, $translate, translationService, $rootScope) {

}]);*/

function getCookie(Name) {
        var search = Name + "="
        var returnvalue = "";
        if (document.cookie.length > 0) {
            offset = document.cookie.indexOf(search)
            // if cookie exists
            if (offset != -1) { 
                offset += search.length
                // set index of beginning of value
                end = document.cookie.indexOf(";", offset);
                // set index of end of cookie value
                if (end == -1) end = document.cookie.length;
                returnvalue=unescape(document.cookie.substring(offset, end))
            }
        }
        return returnvalue;
    }