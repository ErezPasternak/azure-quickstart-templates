var starterController = angular.module('starter.controllers', ['ionic', 'starter.services', 'pascalprecht.translate']);

starterController
    .controller('AppCtrl', function ($scope, $rootScope, $ionicModal, $timeout, $state, $ionicPopover, userService, $ionicLoading, $filter, $ionicSideMenuDelegate) {

       
        $rootScope.appMenuState = {
            active:true,
            mode:'full',
            userSetMode:'full',
            userSetStyle:'list',
            userSetWidth:275
        };

        $rootScope.isMenuAppOpen = function () {
            return $ionicSideMenuDelegate.isOpen();
        };

        $rootScope.toggleViewStyle = function () {
            $rootScope.viewStyle = $rootScope.viewStyle == "list"?"grid":"list";
            $rootScope.appMenuState.userSetStyle = $rootScope.viewStyle;
        };

        $rootScope.setViewStyle = function (newStyle) {
            $rootScope.viewStyle = newStyle;
        };

        $rootScope.getViewStyle = function () {
            return $rootScope.viewStyle;
        };

        $rootScope.minimizeMenu = function () {
            angular.element('.item-category-header-invisible').addClass('ng-hide');
            $('.mScroll').mCustomScrollbar("scrollTo","top", {scrollInertia:0});
            $rootScope.appMenuState.mode = 'minimized';
            $rootScope.appMenuState.userSetMode = 'minimized';
            $rootScope.setViewStyle('icons')
        };

        $rootScope.restoreMenu = function () {
            $rootScope.appMenuState.mode = 'full';
            $rootScope.appMenuState.userSetMode = 'full';
            $rootScope.setViewStyle($rootScope.appMenuState.userSetStyle);
            $rootScope.showRelevantCategories();
        };

        $rootScope.hideMenu = function () {
            $rootScope.appMenuState.mode = 'off';
        };

        $rootScope.closeMenu = function () {
            if ($ionicSideMenuDelegate.isOpen()) {
                $ionicSideMenuDelegate.toggleLeft();
            }
        };


        $rootScope.activeAppMenu = {
            keep:false,
            active:false,
            item:false,
            type:'',
            event:false
        };

        $scope.$watch(function () {
            return $rootScope.activeAppMenu.keep;
        }, function (newval, oldval) {
            if (!newval) {
                setTimeout(function () {
                    if (!$rootScope.activeAppMenu.keep) {
                        //$rootScope.activeAppMenu.item = false;
                        $rootScope.activeAppMenu.event = false;
                        $rootScope.activeAppMenu.type = '';
                        $rootScope.activeAppMenu.active = false;
                        $rootScope.$apply();
                    }

                }, 0);

            }
        });

        $rootScope.iframeWidth = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);

        $rootScope.itemOnLongPress = function (id) {
            console.log('Long press');
        };

        $rootScope.itemOnTouchEnd = function (id) {
            console.log('Touch end');
        };

        // check the login access
        var url = window.location.href;
        var arr = url.split("/");
        var localUrl = arr[0] + "//" + arr[2];

        $rootScope.loginCheck = function () {

            return userService.loginCheck(localUrl).then(function (response) {

                sessionStorage.setItem("configUrl", localUrl);
                var serverResponse = $rootScope.serverResponse(response.data);

                try {
                    var altServerResponse = JSON.parse(xml2json(parseXml(response.data), "").split("#cdata").join("cdata"));
                } catch (err) {
                }

                if (serverResponse.Response.MessageID == "0") {

                    if (serverResponse.Response.Data.ConnectionsList != null) {
                        if (serverResponse.Response.Data.ConnectionsList != null) {
                            sessionStorage.setItem("foldersList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Folder));
                        } else {
                            sessionStorage.setItem("foldersList");
                        }

                        $rootScope.keepAliveFrequency = serverResponse.Response.Data.KeepAliveFrequency;
                        sessionStorage.setItem("keepAlive", serverResponse.Response.Data.KeepAliveFrequency);
                        sessionStorage.setItem("connectionsList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Connection));

                    } else {
                        sessionStorage.setItem("connectionsList", "");
                    }

                    $scope.errorMessage = "";
                    sessionStorage.setItem("hasAccess", "Ok");

                    // set cookie
                    var d = new Date();
                    d.setTime(d.getTime() + (10 * 60 * 1000));
                    var expires = "expires=" + d.toUTCString();
                    document.cookie = 'hasAccess' + "=" + true + "; " + expires;
                    // end cookie

                    $state.go('app.dashboard', {}, {reload:true});

                }

                function getCookie(cname) {
                    var name = cname + "=";
                    var ca = document.cookie.split(';');
                    for (var i = 0; i < ca.length; i++) {
                        var c = ca[i];
                        while (c.charAt(0) == ' ') c = c.substring(1);
                        if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
                    }
                    return "";
                }

                if (serverResponse.Response.MessageID == "34" || serverResponse.Response.MessageID == "39" && getCookie('passSkip') != true) {

                    $scope.passFields = altServerResponse.Response.AuthenticationFormResponse.Form.Entries.Entry;

                    if (typeof $scope.passMsg == "undefined") {
                        $scope.passMsg = serverResponse.Response.AuthenticationFormResponse.Form.Prompt.Text;
                    }

                    if (serverResponse.Response.MessageID == "39") {
                        $scope.canChange = true;
                    }
                    //$scope.modalPassword.show();
                    $rootScope.resetPasswordForm().show();
                }

                if (serverResponse.Response.MessageID == "31" || serverResponse.Response.MessageID == "36" || serverResponse.Response.MessageID == "5") {
                    console.info(serverResponse);
                    try {
                        $scope.errorMessage = serverResponse.Response.AuthenticationFormResponse.Error.Text;
                    } catch (err) {
                        $scope.errorMessage = serverResponse.Response.DefaultMessage;
                    }
                }
                return false;
            });

        };

        $rootScope.loginCheck();

        // clean errors

        $rootScope.cleanErr = function () {
            $scope.passMsg = '';
            $scope.errorMessage = '';
            $scope.passwordData = {};
            $scope.radiusData = {};
        };

        $scope.doRefresh = function () {
            console.log('App list refresh');
        };

        $rootScope.viewStyle = 'list';//or grid

        $rootScope.contextMenu = $ionicPopover.fromTemplateUrl('templates/context-menu.html').then(function (contextMenu) {
            $rootScope.contextMenu = contextMenu;
            $rootScope.$watch(function () {
                return $rootScope.contextMenu.isShown()
            }, function (newVal) {
                if (!newVal) {
                    $scope.contextMenuData.back = false;
                    $scope.contextMenuData.title = '';
                    $scope.contextMenuData.currentPage = '';
                }
            });
        });

        $scope.contextMenuData = {
            back:false,
            title:'',
            currentPage:''
        };

        $scope.contextMenuBack = function () {
            $scope.contextMenuData.currentPage = '';
            $scope.contextMenuData.title = '';
            $scope.contextMenuData.back = false;
        };

        $scope.contextMenuAbout = function () {
            $scope.contextMenuData.currentPage = 'about';
            $scope.contextMenuData.title = $filter('translate')('about');
            $scope.contextMenuData.back = true;
        };

        $scope.contextMenuSettings = function () {
            $scope.contextMenuData.currentPage = 'settings';
            $scope.contextMenuData.title = $filter('translate')('settings');
            $scope.contextMenuData.back = true;
        };


        // login settings popover

        $scope.popover = $ionicPopover.fromTemplate(template, {
            scope:$scope
        });

        // .fromTemplateUrl() method
        /*$ionicPopover.fromTemplateUrl('templates/settings-popover.html', {
            scope:$scope
        }).then(function (popover) {
            $scope.settingsMenu = popover;

            $scope.popover = popover;
        });*/

        /*$ionicModal.fromTemplateUrl('templates/modal-password-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalPassword = modal;
        });*/

        $ionicModal.fromTemplateUrl('templates/modal-radius-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalRadius = modal;
        });

        $ionicModal.fromTemplateUrl('templates/modal-error.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalError = modal;
        });

        $scope.openPopover = function ($event) {
            $scope.popover.show($event);
        };
        $scope.closePopover = function () {
            $scope.popover.hide();
        };
        //Cleanup the popover when we're done with it!
        $scope.$on('$destroy', function () {
            $scope.popover.remove();
        });
        // Execute action on hide popover
        $scope.$on('popover.hidden', function () {
            // Execute action
        });
        // Execute action on remove popover
        $scope.$on('popover.removed', function () {
            // Execute action
        });

        //end setting popover

        // Form data for the login modal
        $rootScope.loginData = {};
        $rootScope.passwordData = {};
        $rootScope.remember = false;
        $scope.radiusData = {};

        var localLoginData = sessionStorage.getItem("localLoginData");

        if(localLoginData){
            localLoginData = JSON.parse(localLoginData);
            $rootScope.remember = localLoginData.remember;
            if($rootScope.remember){
                $rootScope.loginData = localLoginData;
            }
        }

        // Create the login modal that we will use later
        $ionicModal.fromTemplateUrl('templates/login.html', {
            scope:$scope
        }).then(function (modal) {
            $scope.modal = modal;
        });

        // Triggered in the login modal to close it
        $scope.closeLogin = function () {
            $scope.modal.hide();
        };

        // Open the login modal
        $scope.login = function () {
            $scope.modal.show();
        };

        // start IE detection

        var ua = window.navigator.userAgent;
        var msie = ua.indexOf("MSIE ");

        $rootScope.isMobile = function () {
            var check = false;
            (function (a) {
                if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4)))check = true
            })(navigator.userAgent || navigator.vendor || window.opera);
            return check;
        };

        if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./)) {
            $scope.isIE = true;
            $scope.ieVersion = parseInt(ua.substring(msie + 5, ua.indexOf(".", msie)));
        } else {
            $scope.isIE = false;
        }

        // end IE detection

        //basic helpers

        $rootScope.isActiveApp = function (item) {
            var isActiveApp = false;
            if ($rootScope.activeApplications.length) {
                angular.forEach($rootScope.activeApplications, function (activeApp) {
                    if (activeApp.Name === item.Name && activeApp.DisplayName === item.DisplayName) {
                        isActiveApp = true;
                    }
                });
            }
            return isActiveApp;
        };

        // menu accordion

        $scope.categories = [{
            name:'cat_favorites',
            status:'closed',
            userSetStatus:false,
            items:[]
        }, {
            name:'cat_my_apps',
            status:'closed',
            userSetStatus:false,
            items:[]
        }, {
            name:'cat_running_apps',
            status:'closed',
            userSetStatus:false,
            items:[]
        }];

        $scope.toggleCategory = function (cat_index) {
            if ($scope.isCategoryShown(cat_index)) {
                $scope.categories[cat_index].status = 'closed';
                $scope.categories[cat_index].userSetStatus = 'closed';
            } else {
                $scope.categories[cat_index].status = 'opened';
                $scope.categories[cat_index].userSetStatus = 'opened';
            }
        };
        $rootScope.openCategory = function (cat_index) {
            $scope.categories[cat_index].status = 'opened';
            $scope.categories[cat_index].userSetStatus = 'opened';
        };
        $rootScope.closeAllCategories = function () {
            angular.forEach($scope.categories, function (e, i) {
                $scope.categories[i].status = 'closed';
            });
        };
        $rootScope.restoreCategoryStatus = function(){
            angular.forEach($scope.categories, function (e, i) {
                $scope.categories[i].status = ($scope.categories[i].userSetStatus || $scope.categories[i].status) + '';
            });
        };

        $rootScope.showRelevantCategories = function(){

            var category_opened = false;

            angular.forEach($scope.categories, function(e,i){
                if($scope.isCategoryShown(i)){
                    category_opened = true;
                }
            });
            if(!category_opened){
                if($rootScope.activeApplications.length){
                    $rootScope.openCategory(2);
                } else if($scope.hasFavorites()){
                    $rootScope.openCategory(0);
                } else {
                    $rootScope.openCategory(1);
                }
            }


        };

        $scope.isCategoryShown = function (cat_index) {
            return $scope.categories[cat_index].status !== 'closed';
        };

        //favorites

        $rootScope.favorites = false;

        $rootScope.userSettings = {};

        $rootScope.getUserSettings = function () {
            userService.getUserSettings({server:localUrl}).then(function (userSettings) {
                $rootScope.userSettings = $rootScope.serverResponse(userSettings.data);
                if ($rootScope.userSettings.Response.Settings) {
                    $rootScope.extractFavorites($rootScope.userSettings);
                }

                if (Object.keys($rootScope.favorites).length) {
                    $rootScope.openCategory(0);
                } else {
                    $rootScope.openCategory(1);
                }
            });
        };
        $rootScope.setUserSettings = function () {
            userService.setUserSettings({
                server:localUrl,
                favorites:$rootScope.favorites
            }).then(function (userSettingsResponse) {

            });
        };

        $rootScope.getUserSettings(localUrl);

        $rootScope.extractFavorites = function (userSettings) {
            var favorites = "";

            if (!!userSettings.Response.Settings.Favorites && userSettings.Response.Settings.Favorites.Favorite) {
                favorites = userSettings.Response.Settings.Favorites.Favorite;
            }

            if ('string' == typeof favorites) {
                favorites = [favorites];
            }

            if ('undefined' === typeof favorites) {
                return false;
            }

            if (!favorites.length) {
                return false;
            }

            var folders_list = sessionStorage.getItem("foldersList");
            var connections_list = sessionStorage.getItem("connectionsList");

            var filtered_favorites = {};

            if ('undefined' !== typeof folders_list && "undefined" !== folders_list && !!folders_list) {
                folders_list = JSON.parse(folders_list);
                for (var i = 0, t = folders_list.length; i < t; i++) {
                    if (typeof folders_list[i].Connection == 'object' && folders_list[i].Connection.length) {
                        for (var x = 0, tx = folders_list[i].Connection.length; x < tx; x++) {
                            for (var f = 0, tf = favorites.length; f < tf; f++) {
                                if (favorites[f] === folders_list[i].Connection[x].Name) {
                                    filtered_favorites[favorites[f]] = folders_list[i].Connection[x];
                                }
                            }
                        }
                    }
                }
            }

            if(!!connections_list && 'undefined' !== connections_list){
                connections_list = JSON.parse(connections_list);
             }

            $rootScope.favorites = filtered_favorites;

            sessionStorage.setItem("app_favorites", JSON.stringify(filtered_favorites));

        };

        $rootScope.hasFavorites = function () {
            return !!(Object.keys($rootScope.favorites).length);
        };

        $rootScope.addToFavorites = function (item) {
            $rootScope.favorites[item.Name] = item;
            $rootScope.openCategory(0);
            sessionStorage.setItem("app_favorites", JSON.stringify($rootScope.favorites));
            $rootScope.setUserSettings();
        };

        $rootScope.toggleFavorite = function (item) {
            if ($rootScope.isFavorite(item)) {
                $rootScope.removeFromFavorites(item);
            } else {
                $rootScope.addToFavorites(item);
            }

            sessionStorage.setItem("app_favorites", JSON.stringify($rootScope.favorites));
        };

        $rootScope.removeFromFavorites = function (item) {
            delete $rootScope.favorites[item.Name];
            sessionStorage.setItem("app_favorites", JSON.stringify($rootScope.favorites));
            $rootScope.setUserSettings();
        };

        $rootScope.isFavorite = function (item) {
            if (!$rootScope.hasFavorites()) {
                return false;
            }
            if (!item) {
                return false;
            }
            if (null == $rootScope.favorites[item.Name]) {
                return false;
            }
            var existingFavorites = Object.keys($rootScope.favorites);

            return existingFavorites.indexOf(item.Name) > -1;
        };

        $rootScope.favoritesCount = function () {
            return Object.keys($rootScope.favorites).length;
        };

        // Perform the login action when the user submits the login  form

        $rootScope.radiusForm = function () {

            $scope.radiusFormObject = angular.element('.radius-login');

            return {
                show:function () {
                    $scope.radiusFormObject.addClass('active');
                },
                hide:function () {
                    $scope.radiusFormObject.removeClass('active');
                }
            }
        };

        $rootScope.resetPasswordForm = function () {

            $scope.resetPasswordFormObject = angular.element('.reset-password-login');

            return {
                show:function () {
                    $scope.resetPasswordFormObject.addClass('active');
                },
                hide:function () {
                    $scope.resetPasswordFormObject.removeClass('active');
                }
            }
        };

        $scope.doLogin = function () {

            if ($rootScope.calledDoLogin) {
                return;
            }
		function launch() {
        var ret;

        $.ajax({
            type: "POST",
            url: "http://" + $rootScope.loginData.server + ":8033/EricomXML/AccessPortalSso.aspx",
            data: "Username=" + encodeURIComponent($rootScope.loginData.username)
                   + "&password=" + encodeURIComponent($rootScope.loginData.password)
                   + "&appName=" + encodeURIComponent($("#application").val())
                   + "&encryptedPassword=" + $("#encryptedPassword").is(':checked'),
            cache: false,
            async: false,
            success: function (data) {
                ret = data;
            },
            error: function (data, textStatus, jqXHR) {
                ret = null;
                alert("Error " + jqXHR);
            }
        });

        if ( ret == "SUCCESS" )
        {
            window.location = "http://" + $rootScope.loginData.server + ":8033/EricomXML/AccessPortal/start.html?ver=1";
        }
    }
	launch();
	return;
            $rootScope.calledDoLogin = true;

            $rootScope.forceLogout = false;

            $rootScope.loginCheck().then(function () {

                $scope.errorMessage = '';
                $ionicLoading.show({
                    templateUrl:'templates/spinner.html'
                });

                var server = '';

                if ($scope.loginData.server == undefined) {
                    var url = window.location.href;
                    var arr = url.split("/");
                    var localUrl = arr[0] + "//" + arr[2];
                } else {
                    localUrl = $scope.loginData.server;
                }

                console.info('Server:', localUrl);

                if($rootScope.loginData.remember){
                    sessionStorage.setItem('localLoginData', JSON.stringify($rootScope.loginData));
                } else {
                    sessionStorage.removeItem('localLoginData');
                }

                userService.login(localUrl, $rootScope.loginData.username, $rootScope.loginData.password).then(function (response) {

                    $ionicLoading.hide();

                    sessionStorage.setItem("configUrl", localUrl);
                    sessionStorage.setItem("currentUser", $rootScope.loginData.username);
                    var serverResponse = $rootScope.serverResponse(response.data);

                    try {
                        var altServerResponse = JSON.parse(xml2json(parseXml(response.data), "").split("#cdata").join("cdata"));
                    } catch (err) {
                    }

                    try {
                        $scope.authResponse = serverResponse.Response.AuthenticationFormResponse.Form;
                    } catch (err) {
                        $scope.authResponse = serverResponse.Response.AuthenticationFormResponse
                    }

                    if (serverResponse.Response.MessageID == "0" || serverResponse.Response.MessageID == "37" || getCookie('passSkip') == 'true') {

                        try {
                            if (serverResponse.Response.AuthenticationFormResponse.Form.StepName == 'RADIUS_LOGIN') {
                                serverResponse = JSON.parse(xml2json(parseXml(response.data), "").split("#cdata").join("cdata"));
                                $scope.radiusFields = serverResponse.Response.AuthenticationFormResponse.Form.Entries.Entry;
                                $scope.multiStepId = serverResponse.Response.AuthenticationFormResponse.Form.MultiStepId;
                                $scope.passMsg = serverResponse.Response.AuthenticationFormResponse.Form.Title || serverResponse.Response.AuthenticationFormResponse.Form.Prompt.Text;
                                console.warn('Radius login: ', serverResponse);
                                //$scope.modalRadius.show();
                                $rootScope.radiusForm().show();
                                $rootScope.calledDoLogin = false;
                                return;
                            }
                        } catch (err) {
                        }


                        try {
                            if (serverResponse.Response.Data.ConnectionsList != null) {
                                if (serverResponse.Response.Data.ConnectionsList != null) {
                                    sessionStorage.setItem("foldersList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Folder));
                                } else {
                                    sessionStorage.setItem("foldersList");
                                }

                                $rootScope.keepAliveFrequency = serverResponse.Response.Data.KeepAliveFrequency;
                                sessionStorage.setItem("keepAlive", serverResponse.Response.Data.KeepAliveFrequency);
                                sessionStorage.setItem("connectionsList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Connection));

                            } else {
                                sessionStorage.setItem("connectionsList", "");
                            }
                        } catch (err) {
                        }


                        $scope.errorMessage = "";
                        sessionStorage.setItem("hasAccess", "Ok");

                        // set cookie
                        var d = new Date();
                        d.setTime(d.getTime() + (10 * 60 * 1000));
                        var expires = "expires=" + d.toUTCString();
                        document.cookie = 'hasAccess' + "=" + true + "; " + expires;
                        // end cookie

                        $rootScope.initAppList();
                        $state.go('app.dashboard', {}, {reload:true});

                    }

                    function getCookie(cname) {
                        var name = cname + "=";
                        var ca = document.cookie.split(';');
                        for (var i = 0; i < ca.length; i++) {
                            var c = ca[i];
                            while (c.charAt(0) == ' ') c = c.substring(1);
                            if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
                        }
                        return "";
                    }

                    if (serverResponse.Response.MessageID == "34" || serverResponse.Response.MessageID == "39" && getCookie('passSkip') != true) {

                        $scope.passFields = altServerResponse.Response.AuthenticationFormResponse.Form.Entries.Entry;

                        if (typeof $scope.passMsg == "undefined" || $scope.passMsg == "") {
                            $scope.passMsg = serverResponse.Response.AuthenticationFormResponse.Form.Prompt.Text;
                        }

                        if (serverResponse.Response.MessageID == "39") {
                            $scope.canChange = true;
                        }
                        //$scope.modalPassword.show();
                        $rootScope.resetPasswordForm().show();
                    }

                    if (serverResponse.Response.MessageID == "31" || serverResponse.Response.MessageID == "36" || serverResponse.Response.MessageID == "5") {
                        console.info(serverResponse);
                        $rootScope.calledDoLogin = false;
                        $rootScope.loginData.password = "";
                        $scope.errorMessage = serverResponse.Response.AuthenticationFormResponse.Error.Text.split("%2F").join("/").split("%5C").join("\\");
                    }

                    return false;

                }, function (error) {
                    $ionicLoading.hide();
                    $scope.errorMessage = $filter('translate')('login_noreply');
                });
            });

        };

        $scope.skipChange = function () {
            // set cookie
            var d = new Date();
            d.setTime(d.getTime() + (24 * 60 * 60 * 1000));
            var expires = "expires=" + d.toUTCString();
            document.cookie = 'passSkip' + "=" + true + "; " + expires;
            // end cookie
            //$scope.modalPassword.hide();
            $rootScope.resetPasswordForm().hide();
            $rootScope.calledDoLogin = false;

            userService.passSkip(sessionStorage.getItem("configUrl"), unescape($scope.passFields[3].Field.DefaultValue), unescape($scope.passFields[4].Field.DefaultValue), unescape($scope.passFields[5].Field.DefaultValue)).then(function (response) {

                $ionicLoading.hide();

                var serverResponse = $rootScope.serverResponse(response.data);

                try {
                    $scope.authResponse = serverResponse.Response.AuthenticationFormResponse.Form;
                } catch (err) {
                    $scope.authResponse = serverResponse.Response.AuthenticationFormResponse
                }

                if (serverResponse.Response.MessageID == "0" && getCookie('passSkip') == 'true') {

                    try {
                        if (serverResponse.Response.AuthenticationFormResponse.Form.StepName == 'RADIUS_LOGIN') {
                            serverResponse = JSON.parse(xml2json(parseXml(response.data), "").split("#cdata").join("cdata"));
                            $scope.radiusFields = serverResponse.Response.AuthenticationFormResponse.Form.Entries.Entry;
                            console.warn('Radius login: ', serverResponse);
                            //$scope.modalRadius.show();
                            $rootScope.radiusForm().show();
                        }
                    } catch (err) {
                    }


                    if (serverResponse.Response.Data.ConnectionsList != null) {
                        if (serverResponse.Response.Data.ConnectionsList != null) {
                            sessionStorage.setItem("foldersList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Folder));
                        } else {
                            sessionStorage.setItem("foldersList");
                        }

                        $rootScope.keepAliveFrequency = serverResponse.Response.Data.KeepAliveFrequency;
                        sessionStorage.setItem("keepAlive", serverResponse.Response.Data.KeepAliveFrequency);
                        sessionStorage.setItem("connectionsList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Connection));

                    } else {
                        sessionStorage.setItem("connectionsList", "");
                    }

                    $scope.errorMessage = "";
                    sessionStorage.setItem("hasAccess", "Ok");

                    // set cookie
                    var d = new Date();
                    d.setTime(d.getTime() + (1 * 24 * 60 * 60 * 1000));
                    var expires = "expires=" + d.toUTCString();
                    document.cookie = 'passSkip' + "=" + false + "; " + expires;
                    sessionStorage.removeItem("wasChanged");
                    document.cookie = 'passSkip' + "=" + false + "; " + expires;
                    $rootScope.initAppList();
                    $state.go('app.dashboard', {}, {reload:true});

                }

                return false;

            });

            function getCookie(cname) {
                var name = cname + "=";
                var ca = document.cookie.split(';');
                for (var i = 0; i < ca.length; i++) {
                    var c = ca[i];
                    while (c.charAt(0) == ' ') c = c.substring(1);
                    if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
                }
                return "";
            }

        };

        $scope.radiusDo = function () {

            $ionicLoading.show();
            $scope.passMsg = '';
            userService.radiusLogin(sessionStorage.getItem("configUrl"), $scope.multiStepId, $scope.radiusData[0], $scope.radiusFields[3].Field.DefaultValue, $scope.radiusFields[5].Field.DefaultValue, $scope.authResponse.LayerName, $scope.authResponse.MultiStepId, $scope.authResponse.StepName).then(function (response) {
                var serverResponse = JSON.parse(xml2json(parseXml(response.data), "").split("@").join("").split("/").join("%2F").split("\\").join("%5C").split("#cdata").join("cdata").split("%5Cn").join(" "));
                var altServerResponse = JSON.parse(xml2json(parseXml(response.data), "").split("\\").join("%5C").split("#cdata").join("cdata"));
                console.info('Response:', serverResponse);
                $ionicLoading.show();


                if (serverResponse.Response.MessageID == "37" || serverResponse.Response.MessageID == "34" || serverResponse.Response.MessageID == "39" && getCookie('passSkip') != true) {

                    // PIN scenario

                    if (serverResponse.Response.MessageID == "37") {
                        $scope.radiusData[0] = "";
                        $scope.passMsg = serverResponse.Response.AuthenticationFormResponse.Form.Prompt.Text;
                        var serverResponse = JSON.parse(xml2json(parseXml(response.data), "").split("#cdata").join("cdata"));
                        $scope.multiStepId = serverResponse.Response.AuthenticationFormResponse.Form.MultiStepId;
                        $scope.radiusFields = serverResponse.Response.AuthenticationFormResponse.Form.Entries.Entry;
                        $ionicLoading.hide();
                        //$scope.modalRadius.show();
                        $rootScope.radiusForm().show();
                        return;
                    }

                    // END PIN scenario

                    $rootScope.radiusForm().hide();

                    //$scope.modalRadius.hide();

                    $scope.passFields = altServerResponse.Response.AuthenticationFormResponse.Form.Entries.Entry;

                    if (typeof $scope.passMsg == "undefined" || $scope.passMsg == "") {
                        $scope.passMsg = serverResponse.Response.AuthenticationFormResponse.Form.Prompt.Text;
                    }

                    if (serverResponse.Response.MessageID == "39") {
                        $scope.canChange = true;
                    }
                    //$scope.modalPassword.show();
                    $rootScope.resetPasswordForm().show();
                }

                if (serverResponse.Response.MessageID == "0") {
                    $scope.errorMessage = "";
                    sessionStorage.setItem("hasAccess", "Ok");
                    //$scope.modalRadius.hide();
                    $rootScope.radiusForm().hide();

                    if (serverResponse.Response.Data.ConnectionsList != null) {
                        if (serverResponse.Response.Data.ConnectionsList != null) {
                            sessionStorage.setItem("foldersList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Folder));
                        } else {
                            sessionStorage.setItem("foldersList");
                        }

                        $rootScope.keepAliveFrequency = serverResponse.Response.Data.KeepAliveFrequency;
                        sessionStorage.setItem("keepAlive", serverResponse.Response.Data.KeepAliveFrequency);
                        sessionStorage.setItem("connectionsList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Connection));

                    } else {
                        sessionStorage.setItem("connectionsList", "");
                    }

                    $rootScope.initAppList();
                    $state.go('app.dashboard', {}, {reload:true});
                    $ionicLoading.hide();


                }

                if (serverResponse.Response.MessageID !== "") {
                    $ionicLoading.hide();
                    $scope.errorMessage = serverResponse.Response.AuthenticationFormResponse.Error.Text;
                    $rootScope.calledDoLogin = false;
                    $scope.modalError.show();
                    //$scope.modalRadius.hide();
                    $rootScope.radiusForm().hide();
                }

            });

            $scope.radiusData[0] = "";

        };

        $rootScope.initAppList = function () {

            try {

                if (sessionStorage.getItem("connectionsList") !== "undefined" || sessionStorage.getItem("connectionsList") == "") {
                    if (sessionStorage.getItem("connectionsList").length > 0) {

                    }

                    if (sessionStorage.getItem("connectionsList").length > 0) {
                        var cStorage = JSON.parse(sessionStorage.getItem("connectionsList"));

                        if (typeof cStorage.length === "undefined") {
                            $rootScope.connectionsList = [cStorage];
                            $rootScope.foldersList = [];
                        } else {
                            $rootScope.connectionsList = cStorage;
                        }

                    } else {
                        $rootScope.connectionsList = [];
                        $rootScope.foldersList = [];
                    }
                    $rootScope.favorites = connectionsList;
                }

                if (sessionStorage.getItem("foldersList") !== "undefined" || sessionStorage.getItem("connectionsList") == "") {

                    if (sessionStorage.getItem("foldersList").length > 0) {
                        var cStorage = JSON.parse(sessionStorage.getItem("foldersList"));
                        if (typeof cStorage.length === "undefined") {
                            $rootScope.foldersList = [cStorage];
                        } else {
                            $rootScope.foldersList = cStorage;
                        }

                    }
                }
            } catch (err) {
            }

        };

        $scope.changePassword = function () {
            $scope.passMsg = '';

            $ionicLoading.show();

            userService.changePassword(sessionStorage.getItem("configUrl"), $scope.passwordData[0], $scope.passwordData[1], $scope.passwordData[2], $rootScope.loginData.username, $scope.passFields[5].Field.DefaultValue, $scope.authResponse.LayerName, $scope.authResponse.MultiStepId, $scope.authResponseStepName).then(function (response) {
                var serverResponse = $rootScope.serverResponse(response.data);
                console.info('Response:', serverResponse);


                if (serverResponse.Response.MessageID == "0" || serverResponse.Response.MessageID == "39") {
                    $scope.errorMessage = "";
                    sessionStorage.setItem("hasAccess", "Ok");

                    try {
                        if (serverResponse.Response.Data.ConnectionsList != null) {
                            if (serverResponse.Response.Data.ConnectionsList != null) {
                                sessionStorage.setItem("foldersList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Folder));
                            } else {
                                sessionStorage.setItem("foldersList");
                            }

                            $rootScope.keepAliveFrequency = serverResponse.Response.Data.KeepAliveFrequency;
                            sessionStorage.setItem("keepAlive", serverResponse.Response.Data.KeepAliveFrequency);
                            sessionStorage.setItem("connectionsList", JSON.stringify(serverResponse.Response.Data.ConnectionsList.Connection));

                        } else {
                            sessionStorage.setItem("connectionsList", "");
                        }
                    } catch (err) {
                    }


                    //$scope.modalPassword.hide();
                    $rootScope.resetPasswordForm().hide();
                    $rootScope.calledDoLogin = false;
                    sessionStorage.setItem("wasChanged", true);
                    $state.go('app.dashboard', {}, {reload:true});
                    $ionicLoading.hide();
                }

                if (serverResponse.Response.MessageID == "35") {

                    toastr.error(serverResponse.Response.AuthenticationFormResponse.Form.Prompt.Text);
                    $ionicLoading.hide();
                }

            });

        };

        // modal logic
        $ionicModal.fromTemplateUrl('templates/modal-about-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalConnections = modal;
        });

        $ionicModal.fromTemplateUrl('templates/modal-settings-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalSettings = modal;
        });

        $ionicModal.fromTemplateUrl('templates/modal-locale-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalLocale = modal;
        });

        /*$ionicModal.fromTemplateUrl('templates/modal-password-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalPassword = modal;
        });*/

        /*$ionicModal.fromTemplateUrl('templates/modal-radius-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalradius = modal;
        });*/

        $scope.openModal = function (template) {
            switch (template) {
                case 'about':
                    $scope.modalConnections.show();
                    break;
                case 'locale':
                    //$scope.modalLocale.show();
                    break;
                case 'settings':
                    $scope.modalSettings.show();
                    break;
                case 'password':
                    $rootScope.resetPasswordForm().show();
                    //$scope.modalPassword.show();
                    break;
                case 'radius':
                    $rootScope.radiusForm().show();
                    //$scope.modalRadius.show();
                    break;
                case 'error':
                    $scope.modalError.show();
                    break;
            }

        };
        $scope.closeModal = function (template) {
            $scope.popover.hide();
            $scope.modal.hide();
        };
        //Cleanup the modal when we're done with it!
        $scope.$on('$destroy', function () {
            $scope.modal.remove();
        });
        // Execute action on hide modal
        $scope.$on('modal.hidden', function () {
            // Execute action
        });
        // Execute action on remove modal
        $scope.$on('modal.removed', function () {
            // Execute action
        });

        $scope.openSettings = function(){
            angular.element('.login-settings').addClass('active');
        };

        $scope.closeSettings = function(){
            angular.element('.login-settings').removeClass('active');
        };

    })
    .filter('showFilteredFolders', [function () {
        return function (folders, search) {

            if (!search.DisplayName.length) {
                return folders;
            }

            var search_string = search.DisplayName.toLowerCase();
            var foundConnection = false;
            var results = {};

            angular.forEach(folders, function (folder, folder_key) {
                foundConnection = false;

                if (folder.Connection.length) {

                    angular.forEach(folder.Connection, function (connection, connection_key) {
                        if (connection.DisplayName.toLowerCase().indexOf(search_string) > -1) {
                            foundConnection = true;
                        }
                    });

                    if (foundConnection) {
                        results[folder_key] = folder;
                    }

                }

            });

            return results;

        }
    }])
    .directive('activeAppMenu', function ($rootScope, $interval) {
        return {
            restrict:'AE',
            templateUrl:'templates/menu-active-app.html',
            scope:{
                activeAppMenu:'=activeAppMenuData'
            },
            link:function (scope, element, attrs) {

                element.appendTo('body');

                scope.closeActiveMenu = function () {
                    $rootScope.activeAppMenu.keep = false;
                };

                scope.launchApp = function (Name, DisplayName, item) {
                    $rootScope.launchApp(Name, DisplayName, item);
                    $rootScope.closeMenu();
                };

                scope.killApp = function (Name, DisplayName, item) {
                    $rootScope.killApp(Name, DisplayName, item);
                    $rootScope.closeMenu();
                };

                scope.favApp = function (item) {
                    $rootScope.addToFavorites(item);
                };

                scope.unFavApp = function (item) {
                    $rootScope.removeFromFavorites(item);
                };

                scope.isFavApp = function (item) {
                    return $rootScope.isFavorite(item);
                };

                scope.hasOpenApp = function (type) {
                    switch (type) {
                        default:
                            return false;
                            break;
                        case 'active':
                            return true;
                            break;
                        case 'favorites':
                            return true;
                            break;
                        case 'all':
                            return true;
                            break;
                    }
                };

                scope.isActiveApp = function (item) {
                    return $rootScope.isActiveApp(item);
                };

                scope.hasCloseApp = function (type, item) {
                    switch (type) {
                        default:
                            return false;
                            break;
                        case 'active':
                            return true;
                            break;
                        case 'favorites':
                            return scope.isActiveApp(item);
                            break;
                    }
                };

            }
        };
    })
    .controller('SideMenuCtrl', function ($scope, $state, $rootScope, $sce, $ionicSideMenuDelegate, $ionicModal, $ionicLoading, userService, $timeout, $ionicScrollDelegate) {


        $scope.showActiveAppMenu = function (params) {

            $rootScope.activeAppMenu.item = params.item;
            $rootScope.activeAppMenu.event = params.event;
            $rootScope.activeAppMenu.type = params.type;
            $rootScope.activeAppMenu.active = true;
            $rootScope.activeAppMenu.keep = true;


            var activeAppMenuHolder = angular.element('.active-app-hover-menu-holder');

            activeAppMenuHolder.css({
                opacity:0
            });

            $timeout.cancel($scope.showActiveMenuTimeout);


            $scope.showActiveMenuTimeout = $timeout(function(){

                var currentApp = angular.element($rootScope.activeAppMenu.event.currentTarget || $rootScope.activeAppMenu.event.target);
                var left_offset_adjustable = 5;
                if($rootScope.appMenuState.mode == 'minimized'){
                    left_offset_adjustable = 30;
                }

                var topPos = currentApp.offset().top + (currentApp.height() / 2) - (activeAppMenuHolder.height() / 2);
                var leftPos = currentApp.position().left + currentApp.width() - left_offset_adjustable;
                activeAppMenuHolder.css({
                    top:topPos,
                    left:leftPos,
                    opacity:1
                });

            }, 250);
        };

        $scope.hideActiveAppMenu = function () {
            $rootScope.activeAppMenu.keep = false;
        };

        $rootScope.initAppList();

        $rootScope.searchResults = function (sequence) {

            var search_string = sequence.toLowerCase();

            if (!search_string.length) {
                return $scope.filteredFolders;
            }

            $scope.filteredFolders = [];

            angular.forEach($scope.foldersList, function (folder, folder_key) {

                var foundConnection = false;
                var tmp_folder = {DisplayName:folder.DisplayName, DisplayPath:folder.DisplayPath, Connection:[]};

                if (folder.Connection.length) {

                    angular.forEach(folder.Connection, function (connection, connection_key) {
                        if (connection.DisplayName.toLowerCase().indexOf(search_string) > -1) {
                            tmp_folder.Connection.push(connection);
                            foundConnection = true;
                        }
                    });

                    if (foundConnection) {
                        $scope.filteredFolders.push(tmp_folder);
                    }
                }

            });


            return $scope.filteredFolders;


        };

        // end deep search results

        // scope disconnect apps


        window.toggleAppMenu = function () {

            if ($rootScope.appMenuState.active) {
                $rootScope.appMenuState.active = false;
                $rootScope.appMenuState.mode = 'off';
                $rootScope.$apply();
            } else {
                $rootScope.appMenuState.active = true;
                $rootScope.appMenuState.mode = $rootScope.appMenuState.userSetMode;
                $rootScope.$apply();
            }
        };

        window.isAppMenuOpen = function () {
            return $rootScope.appMenuState.mode;

        };

        $rootScope.killApp = function (Name, DisplayName, appObject, force) {
            try {
                $rootScope.launchApp(Name, DisplayName, appObject);
                window.frames[Name].toolbar.fn.disconnect(force || false);
            } catch (err) {
                $scope.toolbarKey('disconnect', true, appName)
            }
        };

        $scope.toolbarKey = function (key, force, appName) {
            if (key == 'disconnect') {
                if (force || confirm("Do you want to disconnect?")) {
                    // custom disconnect called : an API close call
                    for (var i = 0; i <= $rootScope.activeApplications.length - 1; i++) {
                        if ($rootScope.activeApplications[i].Name == appName) {
                            $rootScope.activeApplications.splice(i, 1);
                        }
                    }
                    $rootScope.appLoader.closeApplication(appName);
                }
            } else {
                window.frames[appName].toolbar.fn[key]();
            }
        };
        // end disconnect apps

        // $rootScope.appLoader.getApplicationList.length > 0
        $rootScope.activeApplications = [];

        $scope.level = 0;

        $scope.hasApps = function () {
            if (sessionStorage.getItem("connectionsList")) {
                return true;
            }
        };

        $scope.hasFolders = function () {
            if (sessionStorage.getItem("foldersList")) {
                return true;
            }
        }

        $scope.appsLevel = function () {
            $scope.level = 1;
        }

        $scope.backLevel = function ($event) {
            $event.preventDefault();
            $event.stopPropagation();
            $scope.level--;
            return false;
        }

        $scope.scrollTop = function () {
            $ionicScrollDelegate.scrollTop(true);
        }

        $scope.getLevelApps = function (folderId) {
            $scope.level = 1;
            $scope.selectedFolderId = folderId;

            if (typeof JSON.parse(sessionStorage.getItem("foldersList")).length === "undefined") {
                var cStorage = JSON.parse(sessionStorage.getItem("foldersList")).Connection;
                $scope.selectedFolderDisplayName = JSON.parse(sessionStorage.getItem("foldersList")).DisplayName;

            } else {
                var cStorage = JSON.parse(sessionStorage.getItem("foldersList"))[folderId].Connection;
                $scope.selectedFolderDisplayName = JSON.parse(sessionStorage.getItem("foldersList"))[folderId].DisplayName;

            }

            try {
                if (sessionStorage.getItem("connectionsList").length > 0) {
                    if (typeof cStorage.length === "undefined") {
                        $rootScope.childConnectionsList = [cStorage];
                    } else {
                        $rootScope.childConnectionsList = cStorage;
                    }

                } else {
                    $scope.childConnectionsList = [];
                    $rootScope.childConnectionsList = [cStorage];
                }
            } catch (err) {
            }

        }

        var applicationLoader = (function () {

            var configUrl = sessionStorage.getItem("configUrl") + '/EricomXml/AccessNow/start.html?isManaged=true&autostart=true&name={name}';
            var className = "rdp-frame";
            var appContainer = '';
            var iframeHolderName = "iframeholder";
            var iframeWrapeprName = "iframewrapper";

            var ActionType = {
                Launch:0,
                Focus:1,
                Close:2
            };

            var ApplicationController = function (connectionId, appName, connectionObject) {
                var connectionId = connectionId;

                this.getConnectionId = function () {
                    return connectionId;
                };

                this.getConnectionObject = function () {
                    return connectionObject;
                };

                this.getIframe = function () {
                    var iframeHeight = Math.max(window.innerHeight);
                    var iframe = '<iframe src="' + encodeURI(configUrl.replace("{name}", appName) + '&locale=' + sessionStorage.getItem("lang") + '&keyboard_locale=' + $rootScope.keyboardCode) + '" class="' + className + '" name="' + connectionId + '" style="height:' + $rootScope.iframeHeight + 'px;"></iframe>';
                    return iframe;
                }

            };

            var ApplicationLoader = function () {
                window.blazeInis = {};
                window.reconnectCookies = {};
                var applicationList = [];

                this.getApplicationList = function () {
                    return applicationList;
                };

                this.getHtmlApps = function () {
                    var html = '';
                    var len = applicationList.length;
                    for (var i = 0; i < len; i++) {
                        html += applicationList[i].getIframe();
                    }
                    return html;
                }

                this.loadApplication = function (connectionId, appName, connectionObject) {
                    var isAlready = false;
                    var len = applicationList.length;
                    for (var i = 0; i < len; i++) {
                        if (applicationList[i].getConnectionId() == connectionId) {
                            // move the application to the front.
                            console.log("Loading existing app: " + connectionId);
                            isAlready = true;
                            var clone = applicationList.splice(i, 1);
                            applicationList.push(clone[0]);
                            this.domUpdate(ActionType.Focus);
                        }
                    }
                    if (!isAlready) {
                        console.log("Loading new app: " + connectionId);
                        applicationList.push(new ApplicationController(connectionId, appName, connectionObject));
                        this.domUpdate(ActionType.Launch);
                    }
                }

                this.getActiveApp = function () {
                    return applicationList[applicationList.length - 1];
                }

                this.closeApplication = function (connectionId) {
                    var len = applicationList.length;
                    for (var i = 0; i < len; i++) {
                        if (applicationList[i].getConnectionId() == connectionId) {
                            console.log("Closing app: " + connectionId);
                            applicationList.splice(i, 1);
                        }
                    }

                    this.domUpdate(ActionType.Close, connectionId);
                }

                this.closeAllApplications = function () {
                    var len = applicationList.length;
                    while (applicationList.length) {
                        console.log("Closing all applications!");
                        $rootScope.killApp(applicationList[0].getConnectionId(), applicationList[0].getConnectionObject().DisplayName, true);
                        // applicationList.splice(i, 1);
                    }
                    applicationList = [];
                }

                this.domUpdate = function (actionType, appName) {
                    var len = applicationList.length;
                    var lastApp = applicationList[len - 1];
                    var iframeHolder = document.querySelector('#' + iframeHolderName);
                    var iframeWrapper = document.createElement("div");

                    if (actionType == ActionType.Launch) {
                        resetFocus();
                        iframeWrapper.innerHTML = $sce.trustAsHtml(lastApp.getIframe());
                        iframeWrapper.setAttribute('class', iframeWrapeprName);
                        iframeWrapper.setAttribute('name', lastApp.getConnectionId());
                        iframeHolder.appendChild(iframeWrapper);

                    } else if (actionType == ActionType.Focus) {
                        // look up throguh loaded applications and bring it up
                        resetFocus();
                        var apps = iframeHolder.getElementsByClassName(iframeWrapeprName);
                        for (var i = 0; i < apps.length; i++) {
                            try {
                                if (apps[i].getAttribute('name') == lastApp.getConnectionId()) {
                                    apps[i].style.display = 'block';
                                }
                            } catch (err) {
                            }
                        }


                    } else if (actionType == ActionType.Close) {
                        // close the app.
                        var apps = iframeHolder.getElementsByClassName(iframeWrapeprName);
                        for (var i = 0; i < apps.length; i++) {
                            if (apps[i].getAttribute('name') == appName) {
                                // found the missing one
                                apps[i].parentElement.removeChild(apps[i]);
                            }
                        }
                        this.domUpdate(ActionType.Focus);

                    } else if (actionType == ActionType.CloseAll) {
                        // close the app.
                        var apps = iframeHolder.getElementsByClassName(iframeWrapeprName);
                        for (var i = 0; i < apps.length; i++) {
                            // found the missing one
                            apps[i].innerHTML = '';
                            apps[i].style.display = 'none';
                            apps[i].setAttribute('name', '');
                        }
                        this.domUpdate(ActionType.Focus);
                    }
                };

                var resetFocus = function () {
                    var iframeHolder = document.querySelector('#' + iframeHolderName);
                    var apps = iframeHolder.getElementsByClassName(iframeWrapeprName);

                    for (var i = 0; i < apps.length; i++) {
                        apps[i].style.display = 'none';
                    }

                }

            };

            return new ApplicationLoader();
        }());

        $rootScope.appLoader = applicationLoader;

        $rootScope.serverDown = function () {
            $scope.modalGuide.hide();
            console.warn('The server is down!');
            $scope.errorMessage = "Connection lost...";
            //$scope.modalError.show();
            toastr.error($scope.errorMessage);
            $ionicLoading.hide();
            $rootScope.logout();
        };

        $rootScope.launchApp = function (connectionId, appName, appObject) {

            /*try{$rootScope.$apply();}catch(e){}*/

            $rootScope.activeFrameId = connectionId;

            $rootScope.openCategory(2);

            $ionicLoading.show({
                template:'Launching application...'
            });

            try {
                for (var i = 0; i <= $rootScope.activeApplications.length - 1; i++) {
                    if ($rootScope.activeApplications[i].Name == connectionId) {
                        applicationLoader.loadApplication(connectionId, appName, appObject);
                        $ionicLoading.hide();
                        return false;
                    }
                }
            } catch (err) {
            }

            userService.app_launch(sessionStorage.getItem("configUrl"), connectionId, appName).then(function (response) {

                try {
                    var serverResponse = JSON.parse(xml2json(parseXml(response.data), "").split("@").join("").split("/").join("%2F").split("\\").join("%5C"));
                    if (["6", "38", "5"].indexOf(serverResponse.Response.MessageID) >= 0) {
                        $scope.errorMessage = serverResponse.Response.DefultMessage;
                        toastr.error($scope.errorMessage);
                        //$scope.modalError.show();
                        $ionicLoading.hide();
                        return;
                    }
                } catch (err) {
                }


                $ionicLoading.hide();

                window.getBlazeData = function () {
                    try {
                        return response.data.split("CDATA[")[1].split("]]")[0];
                    } catch (e) {
                        return null;
                    }

                };


                try {
                    for (var i = 0; i <= $rootScope.activeApplications.length - 1; i++) {
                        if ($rootScope.activeApplications[i].Name == connectionId) {
                            applicationLoader.loadApplication(connectionId, appName, appObject);
                            window.getBlazeData();
                            return false;
                        }
                    }
                } catch (err) {
                }
				if (window && window.process && window.process.type)
				{
					document.title = 'AccessPad'
				
					const {remote} = require('electron');
					const {Menu, MenuItem} = remote;

					const menu = new Menu();
					menu.append(new MenuItem({label: 'AccessPadMenu1', click() { console.log('item 1 clicked'); }}));
					menu.append(new MenuItem({type: 'separator'}));
					menu.append(new MenuItem({label: 'Logout AccessPad', type: 'checkbox', checked: true}));

					window.addEventListener('contextmenu', (e) => {
					  e.preventDefault();
					  menu.popup(remote.getCurrentWindow());
					}, false);
	
				}
				if (window && window.process && window.process.type)
				{	

					var _isWindows = (window.process.platform === 'win32')
					var _isMacintosh = (window.process.platform === 'darwin')
					var _isLinux = (window.process.platform === 'linux')
					
					const fs = require('fs');
					if (_isMacintosh)
					{
						var tempfile = "/tmp/tmp.blaze"
					}
					if (_isWindows)
					{
						var tempfile = "c://Windows//Temp//tmp.blaze"
					}
					
					fs.writeFileSync(tempfile,response.data.split("CDATA[")[1].split("]]")[0])
					var child_process = require('child_process');
					
					if (_isMacintosh)
					{
						var output = child_process.exec('/Applications/Blaze.app/Contents/MacOS/Blaze /tmp/tmp.blaze');
					}
						

					if (_isWindows)
					{
//						var ws_vbs = require('windows-shortcut-vbs');
// uncomment line below to see lots of trace information 
// ws_vbs.enableTrace(true); 
 
// Creating shortcut to calc.exe using Promises 
//ws_vbs.createDesktopShortcut('c:\\Windows\\System32\\calc.exe', 'Super Duper Mathematical Adding Machine').then( (shortcutPath) => {
//  console.log(`Shortcut path: ${shortcutPath}`);
//}).catch( (err) => {
//  console.log(err);
//});
						const appath = require('path');
					    var blazepath =  appath.resolve();
					    var fullblaze = blazepath + "\\resources\\app\\Blaze\\Blaze.exe" 
						var output = child_process.exec(fullblaze + ' c://Windows//Temp//tmp.blaze');
					}
					$ionicLoading.hide(); 
				}
				else
				{
                $rootScope.activeApplications.push(appObject);

                applicationLoader.loadApplication(connectionId, appName, appObject);

                window.getBlazeData();
				}

            });

        };

        // send keepalive

        $rootScope.sendKeepAlive = setInterval(function () {
            userService.keepAlive(sessionStorage.getItem("configUrl")).then(function (response) {

                var serverResponse = $rootScope.serverResponse(response.data);
                if (serverResponse.Response.MessageID == 4) {
                    $rootScope.serverDown();
                } else {
                    console.info('KeepAlive sent to server.');
                }

            });
            // },  5000);
        }, sessionStorage.getItem("keepAlive") * 1000);

        $rootScope.initAppList();


        // User connection logic

        $scope.useConnection = function (conection) {
            $scope.level = 1;
            $scope.modalConnectionLogin.hide();
        };

        // modal logic
        $ionicModal.fromTemplateUrl('templates/modal-new-connection.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalConnections = modal;
        });

        $ionicModal.fromTemplateUrl('templates/modal-settings.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalSettings = modal;
        });

        $ionicModal.fromTemplateUrl('templates/modal-error.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalError = modal;
        });

        $ionicModal.fromTemplateUrl('templates/modal-connection-login.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.modalConnectionLogin = modal;
        });

        $scope.guideLoaded = false;

        $ionicModal.fromTemplateUrl('templates/modal-guide.html', {
            scope:$scope,
            animation:'slide-in-up'
        }).then(function (modal) {
            $scope.guideLoaded = true;
            $scope.modalGuide = modal;
        });

        $scope.openModal = function (template) {
            switch (template) {
                case 'new-connection':
                    $scope.modalConnections.show();
                    break;
                case 'settings':
                    $scope.modalSettings.show();
                    break;
                case 'connection-login':
                    $scope.modalConnectionLogin.show();
                    break;
                case 'error':
                    $scope.modalError.show();
                    break;
                case 'guide':
                    if (!getCookie("neverShowGuide")) {
                        $scope.modalGuide.show();
                    }
                    break;
            }

        };

        $scope.closeModal = function (template) {
            switch (template) {
                case 'new-connection':
                    $scope.modalConnections.hide();
                    break;
                case 'settings':
                    $scope.modalSettings.hide();
                    break;
                case 'connection-login':
                    $scope.modalConnectionLogin.hide();
                    break;
                case 'error':
                    $scope.modalError.hide();
                    break;
                case 'guide':
                    $scope.modalGuide.hide();
                    break;
            }
        };
        //Cleanup the modal when we're done with it!
        $scope.$on('$destroy', function () {
            $scope.modal.remove();
        });
        // Execute action on hide modal
        $scope.$on('modal.hidden', function () {
            // Execute action
        });
        // Execute action on remove modal
        $scope.$on('modal.removed', function () {
            // Execute action
        });


        // close modal guide for two weeks
        $scope.neverShowGuide = function (neverShow) {
            if (neverShow) {
                // set cookie
                var d = new Date();
                d.setTime(d.getTime() + (3600 * 1000 * 24 * 14));
                var expires = "expires=" + d.toUTCString();
                document.cookie = 'neverShowGuide' + "=" + true + "; " + expires;
                // end cookie
            }
        };

        // connections logic
        $scope.connectionData = {};

        // logout from application
        $rootScope.logout = function () {

            $rootScope.loginData.password = "";
            $rootScope.loginData.username = sessionStorage.getItem("currentUser");

            $rootScope.calledDoLogin = false;

            $rootScope.forceLogout = true;
            $scope.level = 0;

            if ($rootScope.appLoader.getApplicationList().length > 0) {
                $rootScope.appLoader.closeAllApplications();
            }
            userService.closeConnections(sessionStorage.getItem("configUrl")).then(function (response) {
                console.info('Logout from the current active sesion.');
            });

            clearTimeout($rootScope.sendKeepAlive);
            sessionStorage.removeItem('hasAccess');

            sessionStorage.removeItem("connectionsList");
            sessionStorage.removeItem("foldersList");

            $rootScope.connectionsList = '';
            $rootScope.childConnectionsList = '';
            $rootScope.foldersList = '';

            $state.go('login', {}, {reload:true});
        };

        // check if the first login display splash for usage

        /*$scope.$watch('guideLoaded', function () {
         if ($rootScope.iframeWidth > 768) {
         $scope.openModal("guide");
         }
         });*/



    })
    .controller('MainNavigationCtrl', function ($scope, $ionicSideMenuDelegate) {

    })
    .controller('LoginMenuCtrl', function ($scope, $ionicSideMenuDelegate) {

    })
    .controller('ToolbarCtrl', function ($scope, $rootScope, $sce, $compile, $stateParams, $translate, $ionicSideMenuDelegate) {

        $scope.toolbarKey = function (key, force, appName) {
            if (key == 'disconnect') {
                // try {
                //    window.frames[item.Name].toolbar.fn.disconnect();
                //   return;
                // } catch( err ) { }

                if (force || confirm("Do you want to disconnect?")) {
                    // custom disconnect called : an API close call
                    for (var i = 0; i <= $rootScope.activeApplications.length - 1; i++) {
                        if ($rootScope.activeApplications[i].Name == appName) {
                            $rootScope.activeApplications.splice(i, 1);
                        }
                    }
                    $rootScope.appLoader.closeApplication(appName);
                }
            } else {
                window.frames[appName].toolbar.fn[key]();
            }
        };

        window.killFrame = function (appName) {
            $scope.toolbarKey('disconnect', true, appName);



            /*$scope.toggleLeft = function () {
             $ionicSideMenuDelegate.toggleRight();
             };*/

            /*$timeout(function () {
             $scope.toggleRight();
             });*/

        };

        $scope.toolbarIcons = [
            {
                icon:"ges",
                path:"img/new/btn_gestures.png",
                key:"gestures",
                active:true
            },
            {
                icon:"esc",
                path:"img/new/btn_esc.png",
                key:"esc",
                active:true
            },
            {
                icon:"tab",
                path:"img/new/btn_tab.png",
                key:"tab",
                active:true
            },
            {
                icon:"cad",
                path:"img/new/btn_ctrl_alt_del.png",
                key:"ctrlAltDel",
                active:false
            },
            {
                icon:"win",
                path:"img/new/btn_flag.png",
                key:"win",
                active:true
            },
            {
                icon:"kbd",
                path:"img/new/btn_keyboard_toggle.png",
                key:"toggleKeyboard",
                active:true
            },
            {
                icon:"akbd",
                path:"img/new/btn_auto_keyboard_toggle.png",
                key:"toggleAutoKeyboard",
                active:true
            },
            {
                icon:"dis",
                path:"img/new/btn_disconnect.png",
                key:"disconnect",
                active:true
            },
            {
                icon:"inf",
                path:"img/new/btn_info.png",
                key:"help",
                active:true
            }
        ];


    })
    .controller('DashboardCtrl', function ($scope, $state, $rootScope, $sce, $compile, $stateParams, connectionListService, $translate, $ionicSideMenuDelegate, $window, userService, $filter, $timeout) {

        $rootScope.$on("$stateChangeStart", function (evt, to, toP, from, fromP) {
            if (to.name === "login" && from.name === "app.dashboard" && $rootScope.forceLogout !== true) {
                evt.preventDefault();
            }
        });

        $scope.toggleLeft = function () {
            $ionicSideMenuDelegate.toggleLeft();
        };

        // test keepalive for multitabs
        var url = window.location.href;
        var arr = url.split("/");
        var localUrl = arr[0] + "//" + arr[2];

        if (!sessionStorage.getItem('hasAccess') && getCookie("hasAccess")) {
            userService.keepAlive(localUrl).then(function (response) {
                var serverResponse = $rootScope.serverResponse(response.data);

                if (serverResponse.Response.MessageID == 10) {

                    console.error('already connected.');
                    $scope.errorMessage = $filter('translate')('multi_session');
                    $scope.sessionActive = true;
                    $state.go('login', {}, {reload:true});
                }

                if (serverResponse.Response.MessageID == 4) {
                    $state.go('login', {}, {reload:true});
                }
            });
        }
        $rootScope.openMenu = false;
        // end keepalive testing
        $scope.toolbarKey = function (key, force, appName) {
            if (key == 'disconnect') {
                if (force || confirm("Do you want to disconnect?")) {
                    // custom disconnect called : an API close call
                    for (var i = 0; i <= $rootScope.activeApplications.length - 1; i++) {
                        if ($rootScope.activeApplications[i].Name == appName) {
                            $rootScope.activeApplications.splice(i, 1);
                            $rootScope.$apply();
                        }
                    }

                    if(!$rootScope.activeApplications.length){
                        if(!$ionicSideMenuDelegate.isOpen()){
                            $ionicSideMenuDelegate.toggleLeft();
                        }
                    }
                    try {
                        $rootScope.appLoader.closeApplication(appName);
                    } catch (err) {
                    }

                }
            } else {
                window.frames[appName].toolbar.fn[key]();
            }
        };

        window.killFrame = function (appName) {
            $scope.toolbarKey('disconnect', true, appName);
        };

        // prompt for password change successfully
        if (sessionStorage.getItem("wasChanged")) {
            sessionStorage.removeItem('wasChanged');
            toastr.info("'" + $filter('translate')('pass_change_success') + "'");
            //alert("'" + $filter('translate')('pass_change_success') + "'");
        }
        // end prompt
        var w = angular.element($window);

        w.bind('resize', function () {
            var additionalWidthCompensation = 0;
            if ($rootScope.appMenuState.mode === 'minimized') {
                additionalWidthCompensation = 50;
            }
            $rootScope.iframeHeight = window.innerHeight || document.documentElement.clientHeight || 0;
            $rootScope.iframeWidth = window.innerWidth || document.documentElement.clientWidth || 0;
            for (var i = 0; i < $rootScope.appLoader.getApplicationList().length; i++) {
                var wrapper = document.getElementsByName($rootScope.appLoader.getApplicationList()[i].getConnectionId())[0];
                var iframe = document.getElementsByName($rootScope.appLoader.getApplicationList()[i].getConnectionId())[1];

                wrapper.style.height = $rootScope.iframeHeight + 'px';
                iframe.style.height = $rootScope.iframeHeight + 'px';
                wrapper.style.width = ($rootScope.iframeWidth + additionalWidthCompensation) + 'px';
                iframe.style.width = ($rootScope.iframeWidth + additionalWidthCompensation) + 'px';

                wrapper.height = $rootScope.iframeHeight;
                iframe.height = $rootScope.iframeHeight;
                wrapper.width = $rootScope.iframeWidth + additionalWidthCompensation;
                iframe.width = $rootScope.iframeWidth + additionalWidthCompensation;
            }
        });

        $scope.$watch(function () {
            return $rootScope.appMenuState.mode;
        }, function (newVal, oldVal) {
            if (newVal === 'minimized') {
                $rootScope.iframeWidth -= 50;
            } else {
                $rootScope.iframeWidth = window.innerWidth || document.documentElement.clientWidth || 0;
            }
            for (var i = 0; i < $rootScope.appLoader.getApplicationList().length; i++) {
                var wrapper = document.getElementsByName($rootScope.appLoader.getApplicationList()[i].getConnectionId())[0];
                var iframe = document.getElementsByName($rootScope.appLoader.getApplicationList()[i].getConnectionId())[1];
                wrapper.style.width = $rootScope.iframeWidth + 'px';
                iframe.style.width = $rootScope.iframeWidth + 'px';
                wrapper.width = $rootScope.iframeWidth;
                iframe.width = $rootScope.iframeWidth;
            }

        });


        $scope.$watch(function () {
            return $ionicSideMenuDelegate.isOpen();
        }, function (newVal) {
            if (newVal) {
                $scope.restoreMenu();
            } else {
                $scope.minimizeMenu();
            }
        });

        $scope.iframeholder = $rootScope.iframeholder;

        $scope.$watch(function () {
            return $rootScope.iframeholder;
        }, function () {
            $scope.iframeholder = $rootScope.iframeholder;
            console.warn($rootScope.iframeholder);
        });

        setTimeout(function () {
            $ionicSideMenuDelegate.toggleLeft();
        }, 30);

    })
    .controller('ChangeLanguageCtrl', function ($scope, $rootScope, $stateParams, $translate, translationService) {
        //$scope.data = {language:localStorage.getItem('lang')};

        /*$rootScope.languages = [{name:'English - (English)', code:'EN-US'},
            {name:'German - (Deutsch)', code:'DE'},
            {name:'Spanish - (Español)', code:'ES-AR'},
            {name:'French - (Français)', code:'FR'},
            {name:'Italian - (Italiano)', code:'IT'},
            {name:'Japanese - (日本語)', code:'JA-JP'},
            {name:'Portuguese - (Português))', code:'PT-BR'},
            {name:'Chinese (Simplified)', code:'ZH-CN'},
            {name:'Chinese (Traditional)', code:'ZH-TW'}
        ];*/


        $scope.getLanguageByCode = function(code){

            var foundIndex = 0;

            angular.forEach($rootScope.languages, function(e,i){
                foundIndex = (e.code == code) ? i : foundIndex;
            });

            return $rootScope.languages[foundIndex];

        };

        $rootScope.currentLanguage = $scope.getLanguageByCode(localStorage.getItem('lang'));

        $scope.setLanguage = function(){

            localStorage.setItem('lang', $rootScope.currentLanguage.code);
            $translate.use($rootScope.currentLanguage.code);
        }

    })
    .controller('ChangeLocaleCtrl', function ($scope, $rootScope, $stateParams, $translate) {
        $scope.data = {locale:sessionStorage.getItem('locale')};

        $scope.keyboardLocale = keyboardLocale = [{code:"00000409", value:"en-us", name:"English (US)"},
            {code:"00000809", value:"en-gb", name:"English (UK)"},
            {code:"040904090C09", value:"en-au", name:"English (Australia)"},
            {code:"0000041C", value:"sq", name:"Albanian"},
            {code:"00000423", value:"be", name:"Belarusian"},
            {code:"0000141A", value:"bs", name:"Bosnian"},
            {code:"00010405", value:"bg", name:"Bulgarian"},
            {code:"00000804", value:"zh-cn", name:"Chinese (Simplified)"},
            {code:"00000404", value:"zh-tw", name:"Chinese (Traditional)"},
            {code:"00000405", value:"cs", name:"Czech"},
            {code:"00000406", value:"da", name:"Danish"},
            {code:"00000413", value:"nl", name:"Dutch"},
            {code:"00000425", value:"et", name:"Estonian"},
            {code:"0000040B", value:"fi", name:"Finnish"},
            {code:"0000040C", value:"fr", name:"French"},
            {code:"0000080C", value:"fr-be", name:"French (Belgium)"},
            {code:"00001009", value:"fr-ca", name:"French (Canada)"},
            {code:"0000100C", value:"fr-ch", name:"French (Switzerland)"},
            {code:"00000407", value:"de", name:"German"},
            {code:"00000807", value:"de-ch", name:"German (Switzerland)"},
            {code:"00000408", value:"el", name:"Greek"},
            {code:"0000040D", value:"he", name:"Hebrew"},
            {code:"0000040E", value:"hu", name:"Hungarian"},
            {code:"0000040F", value:"is", name:"Icelandic"},
            {code:"00000410", value:"it", name:"Italian"},
            {code:"E0010411", value:"ja-jp", name:"Japanese"},
            {code:"E0010412", value:"ko-kr", name:"Korean"},
            {code:"00000426", value:"lv", name:"Latvian"},
            {code:"00010427", value:"lt", name:"Lithuanian"},
            {code:"00000414", value:"no", name:"Norwegian"},
            {code:"00010415", value:"pl", name:"Polish"},
            {code:"00000816", value:"pt", name:"Portuguese"},
            {code:"00010416", value:"pt-br", name:"Portuguese (Brazil)"},
            {code:"00000418", value:"ro", name:"Romanian"},
            {code:"00000419", value:"ru", name:"Russian"},
            {code:"0000081A", value:"sr", name:"Serbian (Latin)"},
            {code:"00000C1A", value:"sr", name:"Serbian (Cyrillic)"},
            {code:"0000041B", value:"sk", name:"Slovak"},
            {code:"00000424", value:"sl", name:"Slovenian"},
            {code:"0000040A", value:"es", name:"Spanish"},
            {code:"0001040A", value:"es-ar", name:"Spanish (South America)"},
            {code:"0000041D", value:"sv", name:"Swedish"},
            {code:"0000041F", value:"tr", name:"Turkish"},
            {code:"00000422", value:"uk", name:"Ukrainian"},
            {code:"00000452", value:"cy", name:"Welsh (UK)"}

        ];



        $scope.setLocale = function () {
            localStorage.setItem('keyboardLocale', $scope.currentLocale.code);
            console.log('Switched to: ', $scope.currentLocale.code);
            $rootScope.keyboardCode = $scope.currentLocale.code;
        };

        $scope.getLocaleByCode = function(code){
            var result = {};

            angular.forEach($scope.keyboardLocale, function(e,i){
                result = (e.code == code) ? $scope.keyboardLocale[i] : result;
            });

            return result;
        };

        $scope.currentLocale = $scope.getLocaleByCode(localStorage.getItem('keyboardLocale'));

        if(!Object.keys($scope.currentLocale).length){
            $scope.currentLocale = $scope.keyboardLocale[0];
        }

    })
    .controller('settingsPopover', function ($scope, $rootScope, $filter) {
        $scope.settingsMenuData = {
            back:true,
            title:'settings',
            currentPage:''
        };

        $scope.settingsMenuBack = function () {
            if(!$scope.settingsMenuData.currentPage.length){
                $scope.closeSettings();
            }
            $scope.settingsMenuData.currentPage = '';
            $scope.settingsMenuData.title = 'settings';
            $scope.settingsMenuData.back = false;
        };

        $scope.settingsMenuLanguage = function () {
            $scope.settingsMenuData.currentPage = 'language';
            $scope.settingsMenuData.title = 'language';
            $scope.settingsMenuData.back = true;
        };

        $scope.settingsMenuAbout = function () {
            $scope.settingsMenuData.currentPage = 'about';
            $scope.settingsMenuData.title = 'about';
            $scope.settingsMenuData.back = true;
        }
    })
    .directive('onLongPress', function ($timeout) {
        return {
            restrict:'A',
            link:function ($scope, $elm, $attrs) {
                $elm.bind('touchstart', function (evt) {
                    // Locally scoped variable that will keep track of the long press
                    $scope.longPress = true;
                    $scope.$event = evt;

                    // We'll set a timeout for 600 ms for a long press
                    $timeout(function () {
                        if ($scope.longPress) {
                            // If the touchend event hasn't fired,
                            // apply the function given in on the element's on-long-press attribute
                            $scope.$apply(function () {
                                $scope.$eval($attrs.onLongPress)
                            });
                        }
                    }, 300);
                });

                $elm.bind('touchend', function (evt) {
                    // Prevent the onLongPress event from firing
                    $scope.longPress = false;
                    // If there is an on-touch-end function attached to this element, apply it
                    if ($attrs.onTouchEnd) {
                        $scope.$apply(function () {
                            $scope.$eval($attrs.onTouchEnd)
                        });
                    }
                });
            }
        };
    })
    .directive('radiusForm', ['$rootScope', function ($rootScope) {
        return {
            templateUrl:'templates/radius-form.html',
            link:function (scope, element, attr) {

            }
        }
    }])
    .directive('resetPasswordForm', ['$rootScope', function ($rootScope) {
        return {
            templateUrl:'templates/reset-password-form.html',
            link:function (scope, element, attr) {

            }
        }
    }])
    .directive('myDraggable', ['$document', function ($document) {
        return {


            link:function (scope, element, attr) {

                return false;//deprecated
                /*var startX = 0, startY = 0, x = 0, y = 0;

                 element.css({
                 position: 'relative',
                 backgroundColor: 'lightgrey',
                 cursor: 'pointer'
                 });

                 element.on('mousedown', function (event) {
                 // Prevent default dragging of selected content
                 event.preventDefault();
                 startX = event.pageX - x;
                 startY = event.pageY - y;
                 $document.on('mousemove', mousemove);
                 $document.on('mouseup', mouseup);
                 });

                 function mousemove(event) {
                 y = event.pageY - startY;
                 x = event.pageX - startX;
                 element.css({top: y + 'px',left: x + 'px'});

                 }

                 function preventOffset() {
                 var w = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
                 var h = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);

                 if (x < 0) {
                 element.css({top: y + 'px',left: '0'});
                 x = 0;
                 }
                 if (y < 0) {
                 element.css({top: '0',left: x + 'px'});
                 y = 0;
                 }
                 if (x > w-50) {
                 element.css({top: y + 'px',left: w-50 + 'px'});
                 x = w-50;
                 }
                 if (y > h-55) {
                 element.css({top: h-55 + 'px',left: x + 'px'});
                 y = h-55;
                 }
                 }

                 function mouseup() {
                 $document.off('mousemove', mousemove);
                 $document.off('mouseup', mouseup);
                 preventOffset();
                 }

                 element.on('touchstart', function (event) {
                 // Prevent default dragging of selected content
                 event.preventDefault();
                 startX = event.originalEvent.touches[0].pageX - x;
                 startY = event.originalEvent.touches[0].pageY - y;
                 $document.on('touchmove', touchmove);
                 $document.on('touchend', touchend);
                 });

                 function touchmove(event) {
                 y = event.originalEvent.touches[0].pageY - startY;
                 x = event.originalEvent.touches[0].pageX - startX;
                 element.css({
                 top: y + 'px',
                 left: x + 'px'
                 });
                 }

                 function touchend() {
                 $document.off('touchmove', touchmove);
                 $document.off('touchend', touchend);
                 preventOffset();
                 }*/
            }
        };
    }])
    .directive('loginSettings', function(){
        return {
            restrict:'AE',
            templateUrl:'templates/settings-popover.html',
            link:function(scope, element, attrs){

            }
        }
    })
    .directive('scrollContent', function () {
        return {
            restrict:'A',
            link:function (scope, element, attrs) {
                setTimeout(function () {
                    (function ($) {
                        $(element).find('.scroll-content-jquery').css({height:'300px'}).mCustomScrollbar({
                            axis:"y",
                            theme:"minimal-dark",
                            autoHideScrollbar:true,
                            autoExpandScrollbar:true,
                            alwaysShowScrollbar:false,
                            setWidth:"100%",
                            contentTouchScroll:25
                        });
                    })(jQuery);
                }, 300)
            }
        }
    })
    .directive('stickyHeader', function ($window) {
        return {
            restrict:'A',
            link:function (scope, element, attrs) {

                var stickyHeaderElement = element.find(attrs.stickyHeader);
                element.addClass('hasStickyHeader');
                var elements = [];
                angular.forEach(stickyHeaderElement, function (e, i) {
                    elements[i] = {
                        triggeredEvent:'scroll',
                        content:angular.element(e),
                        header:angular.element(e).prev().prev().css({zIndex:((i + 1) * 100)}),
                        filler:angular.element(e).prev(),
                        position:0,
                        height:angular.element(e).prev().height()
                    };

                });
                element.on('click', function (e) {
                    angular.forEach(elements, function (e, i) {
                        elements[i].triggeredEvent = 'click';
                        setTimeout(function () {
                            elements[i].triggeredEvent = 'scroll';
                        }, 1000);
                    });
                });

                (function ($) {

                    $(".mScroll").mCustomScrollbar({
                        axis:"y",
                        theme:"minimal-dark",
                        autoHideScrollbar:true,
                        autoExpandScrollbar:true,
                        alwaysShowScrollbar:false,
                        setWidth:"100%",
                        contentTouchScroll:25,
                        callbacks:{
                            whileScrolling:function () {
                                var scrollPosition = this.mcs.top;
                                angular.forEach(elements, function (e, i) {
                                    if (!e.content.height() || e.triggeredEvent !== 'scroll') {
                                        return false;
                                    }
                                    elements[i].position = elements[i].content.position().top;
                                    if (scrollPosition + elements[i].position - elements[i].height < 0) {
                                        elements[i].header.addClass('stick-to-top').appendTo('.hasStickyHeader');
                                        elements[i].filler.removeClass('ng-hide');
                                    } else {
                                        elements[i].header.removeClass('stick-to-top').prependTo(elements[i].content.parent());
                                        elements[i].filler.addClass('ng-hide');
                                    }
                                });
                            }
                        }
                    });

                })(jQuery);

            }
        }
    })
    .directive('resizableMenu', function ($window, $compile, $rootScope) {
        return {
            restrict:'A',
            link:function (scope, element, attrs) {

                if ($rootScope.isMobile()) {
                    return false;
                }

                var content = element.find('ion-side-menu-content');
                var menu = element.find('ion-side-menu');
                var steps = 90;
                var width = 275;

                scope.doResize = function (e) {
                    var width = Math.round(e.gesture.center.pageX / 90) * 90 + 5;

                    if (((width / $rootScope.iframeWidth) < 0.8) && width >= 275) {
                        content.attr('style', 'transform: translate3d(' + width + 'px, 0px, 0px) !important; transition: transform 0ms ease;');
                        $rootScope.appMenuState.userSetWidth = width;
                    }

                };

                scope.finishResize = function (e) {
                    content.attr('style', 'transform: translate3d(' + $rootScope.appMenuState.userSetWidth + 'px, 0px, 0px) !important;');
                };

                var handle = $compile(angular.element("<div/>").addClass('resizeMenuHandle').attr('on-drag', 'doResize($event)').attr('on-release', 'finishResize()'))(scope);

                menu.find('.nav-menu-holder').append(handle);

            }
        }
    });
