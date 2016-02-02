'use strict';

angular.module(['Authentication'])

.controller('registerController',function ($scope, $rootScope, $location, $http , AuthenticationService, Page) {
        $rootScope.compactWidthPage =true;
    
        Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');

        // reset login status
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
.controller('loginDeskController', function($scope, $rootScope, $location, $http, AuthenticationService, Page , $window) {
    $rootScope.compactWidthPage =true;
    
    Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');
	
	AuthenticationService.ClearCredentials();
    
	//login
	$scope.login = function () {
		$scope.dataLoading = true;
		AuthenticationService.Login($scope.username, $scope.password, function (response) {
			if (response.success) {
				AuthenticationService.SetCredentials($scope.username, $scope.password);
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
  
});