'use strict';

angular.module(['Authentication'])

.controller('registerController',function ($scope, $rootScope, $location, $http , AuthenticationService, Page) {
        $rootScope.compactWidthPage =true;
    
        Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');

        // reset login status
        AuthenticationService.ClearCredentials();
        //login-register
        $scope.login = function () {
            $scope.dataLoading = true;
            AuthenticationService.Login($scope.username, $scope.password, $scope.email, function (response) {
                if (response.success) {
                    AuthenticationService.SetCredentials($scope.username, $scope.password, $scope.email);
                    $location.path('/');
                } else {
                    $scope.error = 'Username or password is incorrect';
                    $scope.dataLoading = false;
                }
            });
        };
        
        $scope.register = function() {
            $scope.dataLoading = true;
            AuthenticationService.Register($scope.username, $scope.password, $scope.email, function(response){
               if (response.success) {
                   AuthenticationService.SetCredentials($scope.username, $scope.password, $scope.email);
                   $location.path("/");
               } else {
                   $scope.error = "Something went wrong. Please try again later."
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
.controller('loginDeskController', function($scope, $rootScope, $location, $http, Page , $window) {
    $rootScope.compactWidthPage =true;
    
    Page.setTitle('Service Provider Desktop as a Service (DaaS) Portal');
    
    $scope.login = function () {
        $scope.dataLoading = true;
        var data = {
            command: 'extUser',
            username:$scope.username,
            password:$scope.password
        };
        var config = {
            headers : {
                'Content-Type': 'application/json'
            }
        }
         
         $http.post('api.json', data, config)
            .then(function successCallback(response) {
            // redirect to Desktop  - demo:
            $window.location.href = response.data.link;
            $scope.dataLoading = false;
             
        }, function errorCallback(response) {
            // error
            response.message = 'Username or password is incorrect';
            $scope.error = response.message;
            $scope.dataLoading = false;
             
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