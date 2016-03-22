'use strict';

angular.module(['Authentication'])

.controller('registerController',function ($scope, $rootScope, $location, $http , AuthenticationService, Page, ApplicationData, ApplicationService) {
	$rootScope.compactWidthPage =true;

	Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');
	
	// reset login status
	ApplicationService.GetDefaultApplications(function(response){
		if(!!response && 'TaskWorkers' in response) {
			$rootScope.DefaultApplications = response;
		} else {
			$rootScope.DefaultApplications = null;
		}
	});
	ApplicationService.GetCustomApplications(function(response){
		if(!!response && 'Office' in response) {
			$rootScope.AllApplications = response;
		} else {
			$rootScope.AllApplications = null;
		}
	});	
	AuthenticationService.ClearCredentials();
	
	$scope.register = function() {
		$scope.dataLoading = true;
		AuthenticationService.Register($scope.username, $scope.password, $scope.email, function(response){
		   if (response.success) {
			   AuthenticationService.SetCredentials($scope.username, $scope.password, $scope.email);
			   $location.path("/");
		   } else {
			   $scope.error = response.message;
			   $scope.dataLoading = false;
		   }
		});
	}
    //caurusel
      $scope.myInterval = 8500;
      $scope.noWrapSlides = false;
        $scope.slides = [
            {
                image:'layout/slide-1.jpg',
                id: 0
            },{
                image:'layout/slide-2.jpg',
                id: 1
            }
        ];
      
    })
.controller('loginDeskController', function($scope, $rootScope, $location, $http, AuthenticationService, Page, ApplicationService, $window) {
    $rootScope.compactWidthPage =true;
    
    Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');

	ApplicationService.GetDefaultApplications(function(response){
		if(!!response && 'TaskWorkers' in response) {
			$rootScope.DefaultApplications = response;
		} else {
			$rootScope.DefaultApplications = null;
		}
	});
	ApplicationService.GetCustomApplications(function(response){
		if(!!response && 'Office' in response) {
			$rootScope.AllApplications = response;
		} else {
			$rootScope.AllApplications = null;
		}
	});		
	AuthenticationService.ClearCredentials();
    
	//login
	$scope.login = function () {
		$scope.dataLoading = true;
		AuthenticationService.Login($scope.username, $scope.password, function (response) {
			if (response.success) {
				AuthenticationService.SetCredentials($scope.username, $scope.password, response.email);
				$location.path('/');
			} else {
				$scope.error = 'Username or password is incorrect';
				$scope.dataLoading = false;
			}
		});
	};
    
    //caurusel
      $scope.myInterval = 8500;
      $scope.noWrapSlides = false;
        $scope.slides = [
            {
                image:'layout/slide-1.jpg',
                id: 0
            },{
                image:'layout/slide-2.jpg',
                id: 1
            }
        ];
  
})
.controller('genericController', function ($scope, $rootScope, $location, $http, AuthenticationService, Page, ApplicationService, $window) {
    $rootScope.compactWidthPage = true;

    Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');


    $scope.sendCall = function () {
        $scope.dataLoading = true;

        var data = {
            command: 'Generic'
        };
        var config = {
            headers: {
                'Content-Type': 'application/json'
            }
        }
        $http.post('../command/Generic', data, config)
            .then(function successCallback(response) {
                // let's do something with the result
                $scope.dataLoading = false;
            }, function errorCallback(response) {
                $scope.dataLoading = false;
                // error
            });
    };

    //caurusel
    $scope.myInterval = 8500;
    $scope.noWrapSlides = false;
    $scope.slides = [
        {
            image: 'layout/slide-1.jpg',
            id: 0
        }, {
            image: 'layout/slide-2.jpg',
            id: 1
        }
    ];

});
