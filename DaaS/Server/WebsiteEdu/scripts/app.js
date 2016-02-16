'use strict';
// declare modules
angular.module('Authentication', []);
angular.module('Desk', []);

var app = angular.module('app', [
    'Authentication',
    'Desk',
    'ngRoute',
    'ngCookies',
    'ngAnimate',
	'LocalStorageModule',
    'ui.bootstrap',
    'checklist-model'
])

.config(['$routeProvider', function ($routeProvider) {

    $routeProvider
        .when('/register', {
            controller: 'registerController',
            templateUrl: 'modules/authentication/views/register.html'
        })
        .when('/login', {
            controller: 'loginDeskController',
            templateUrl: 'modules/authentication/views/loginDesk.html'
        })
        .when('/', {
            controller: 'selectDeskController',
            templateUrl: 'modules/home/views/home.html',
            secure: true
        
        })
        .when('/build', {
            controller: 'buildDeskController',
            templateUrl: 'modules/home/views/build.html',
            secure: true
        
        }).when('/access', {
            controller: 'accessDeskController',
            templateUrl: 'modules/home/views/access.html',
            secure: true
        })


        .otherwise({ redirectTo: '/register' });
}])

.factory('Page', function(){
  var title = 'Student Application Portal';
  return {
    title: function() { return title; },
    setTitle: function(newTitle) { title = newTitle; }
  };
})

.factory('ApplicationData', function($rootScope, $http, ApplicationService, localStorageService){
	var app;
	var defaultApps, customApps = {}

	var storage = localStorageService;
	var $scope = $rootScope;
	
	var data = {
		command: 'Get-AppList',
		groups: "TaskWorkers,KnowledgeWorkers,MobileWorkers,Office,Internet,Multimedia"
	};
	var config = {
		headers : {
			'Content-Type': 'application/json'
		}
	}
	$http.post('api', data, config)
	 .then(function successCallback(response) {
		var resp = response.data
		if(!!resp && 'TaskWorkers' in resp) {
			defaultApps = {
				TaskWorkers: resp.TaskWorkers,
				KnowledgeWorkers: resp.KnowledgeWorkers,
				MobileWorkers: resp.MobileWorkers
			}
			
			customApps = {
				Office: resp.Office,
				Internet: resp.Internet,
				Multimedia: resp.Multimedia
			}
			// debugger;
		} else {
			defaultApps = null;
			customApps = null;
		}
	}, function errorCallback(resp) {
		// error
		// callback(response.data);
	});
	return {
		DefaultApps: defaultApps,
		CustomApps: customApps
	};
})

.factory('Wizard', function($route,$location,$rootScope){
   var wizardSteps = [];
    var createAccount = {
            title: 'Registration',
            route:['/register']
    };
    var select_desk = {
            title: 'Select Desktop/Apps/Services',
            route:['/','/build']
    };
    var access = {
            title: 'Access your Desktop',
            route:['/access']
    };
     wizardSteps.push(createAccount);
     wizardSteps.push(select_desk);
     wizardSteps.push(access);

    
    return {
        getWizard: function() { return wizardSteps;},
        isWizard: function() {  
            var fu=false;
            var nextRoute = $route.routes[$location.path()].originalPath;
            for(var i=0;i<wizardSteps.length;i++){
                for(var e=0;e<wizardSteps[i].route.length;e++){
                    if(!fu && wizardSteps[i].route[e] === nextRoute ) {
                            fu=true;
                            $rootScope.activeWizard = wizardSteps[i];
                    }
                }
            }
            $rootScope.isWizard = fu;
            createAccount.done= ($rootScope.securePage)? true : false;
            select_desk.done= ($rootScope.isAccessDesk)? true : false;
            
            $rootScope.bodyClass = (nextRoute == '/' || nextRoute == '/build')? 'body-config' : '';
            
            //console.log($rootScope.securePage);
        }
    }
})

.run(['$rootScope', '$location', '$cookieStore', '$http','$route','Wizard',
    function ($rootScope, $location, $cookieStore, $http, $route,Wizard) {  
    // keep user logged in after page refresh
    $rootScope.globals = $cookieStore.get('globals') || {};
    if ($rootScope.globals.currentUser) {
        $http.defaults.headers.common['Authorization'] = 'Basic ' + $rootScope.globals.currentUser.authdata; // jshint ignore:line
    }

    $rootScope.$on('$locationChangeStart', function (event, next, current) {
        // redirect to login page if not logged in
       /* if ($location.path() !== '/register'  && !$rootScope.globals.currentUser) {
            $location.path('/register');
        }*/
        var nextRoute = $route.routes[$location.path()];

        $rootScope.securePage =(nextRoute.secure)? true : false;

        if (nextRoute.secure && !$rootScope.globals.currentUser) {
            $location.path('/register');
        }else{
        }
        
        Wizard.isWizard();
    })
}]);



app.controller('mainCtrl', function($scope, $route, $rootScope, $location, Page, Wizard) {
    $scope.Page = Page;
    $scope.Wizard = Wizard;
    Wizard.isWizard();
});



