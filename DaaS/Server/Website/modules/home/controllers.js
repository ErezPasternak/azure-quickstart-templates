'use strict';

angular.module('Desk', [])

.controller('selectDeskController', function ($scope,Page, $rootScope, $location, $http, ConfigDesk, ApplicationService) {

    $rootScope.compactWidthPage =false;
    Page.setTitle('Select Your Desktop Profile or Build Your Own');
    $scope.configDesk = ConfigDesk;
    $scope.selectDesk = ConfigDesk.getSelectDesk();
    $scope.imagePath =  ConfigDesk.getImagePath();

    $rootScope.isAccessDesk =false;
    $scope.selectedDesktop = {};
	
	
	
    /* Use this for real 
    ----------------------------------------------*/
    $scope.sendDesk = function () {
        $scope.dataLoading = true;
        var data = {
            command: 'Assign-User',
            username:$rootScope.globals.currentUser.username,
            config:$scope.selectedDesktop.id
        };
        var config = {
            headers : {
                'Content-Type': 'application/json'
            }
        }
        $http.post('api', data, config)
            .then(function successCallback(response) {
            $rootScope.isAccessDesk =true;
            // set data to access page
            $rootScope.accessData = {
                username: $rootScope.globals.currentUser.username,
                password: '******',
                email: $rootScope.globals.currentUser.email,
                url: response.url,
            };
            $location.path('/access');
        }, function errorCallback(response) {
            $scope.dataLoading = false;
            // error
        });   
    };
})

.controller('buildDeskController', function ($scope, Page, $rootScope, $location, $http, ConfigDesk, ApplicationService) {
    $rootScope.compactWidthPage =false;
    Page.setTitle('Customize your Desktop, Applications and Services');

    $scope.config = ConfigDesk.getConfig();
    $scope.imagePath =  ConfigDesk.getImagePath();

    $scope.selectedConfig ={
        hardware:'',
        os:'',
        services:[ ],
        apps:[ ],  
    }; 
    $scope.calcPriceEl= function(obj) {
        var el = 0;
        angular.forEach( obj , function(value, key) {
            if(value.price) el +=  value.price;
        });
        return  el;
    };
	

    /* Use this for real 
    ----------------------------------------------*/
    $scope.sendDesk = function () {
        $scope.dataLoading = true;
        var data = {
            command: 'Custom-Desk',
            username:$rootScope.globals.currentUser.username,
            config:$scope.selectedConfig
        };
        var config = {
            headers : {
                'Content-Type': 'application/json'
            }
        }
        $http.post('api', data, config)
            .then(function successCallback(response) {
            $rootScope.isAccessDesk =true;
            // set data to access page
            $rootScope.accessData = {
                username: 'XXX',
                password: 'XXX',
                email: 'XXX@XXX.com',
                url: 'https://www.blender.org/',
            };
            $location.path('/access');
        }, function errorCallback(response) {
            $scope.dataLoading = false;
            // error
        });   
    };

})
.controller('accessDeskController', function ($scope, Page, $rootScope, $location, $http, $window) {
    $rootScope.compactWidthPage =true;
    Page.setTitle('Your Personal Desktop is Ready');
    
    if(!$rootScope.isAccessDesk)$location.path('/'); 
    
    $scope.goToDesk = function () {
       $window.location.href = $rootScope.accessData.url;
    };
    

})

.factory('ConfigDesk', function($route,$location,$rootScope, ApplicationService){
	if (!('DefaultApplications' in $rootScope)) {
		$rootScope.DefaultApplications = {};
		ApplicationService.GetDefaultApplications(function(response){
			if(!!response && 'TaskWorkers' in response) {
				$rootScope.DefaultApplications = response;
			} else {
				$rootScope.DefaultApplications = null;
			}
		});
	}
	if(!('AllApplications' in $rootScope)) {
		$rootScope.AllApplications = {};
		ApplicationService.GetCustomApplications(function(response){
			if(!!response && 'Office' in response) {
				$rootScope.AllApplications = response;
			} else {
				$rootScope.AllApplications = null;
			}
		});	
	}
	
	
    var selectDesk = [{
        id:1,
        title:'Task Workers',   
        description:'Helpdesk, Call Center, Operation',   
        price:'19',   
        price_term:'month',   
        icon:'d-ic-1.png' , 
        hardware:['1 vCPU','4  GB RAM','50 GB Storage'],  
        apps:$rootScope.DefaultApplications['TaskWorkers']  
    },{
        id:2,
        title:'Knowledge Workers',   
        description:'Marketing, Finance, Administration',   
        price:'32',   
        price_term:'month',   
        icon:'d-ic-2.png' , 
        hardware:['2 vCPU','8 GB RAM','200 GB Storage'],  
        apps:$rootScope.DefaultApplications['KnowledgeWorkers'] 
    },{
        id:3,
        title:'Mobile Workers',   
        description:'Sales, Field Engineers, Executives',   
        price:'45',   
        price_term:'month',   
        icon:'d-ic-3.png' , 
        hardware:['4 vCPU','16 GB RAM','500 GB Storage'],  
        apps:$rootScope.DefaultApplications['MobileWorkers']
    }];
	var getAppPrice = function(appName) {
		var defaultPrice = 2;
		var price = defaultPrice;
		var apps = {
			"Internet Explorer": 3,
			"Command Prompt": 5
		}
		if (appName in apps) {
			price = apps[appName]
		} else price = defaultPrice;
		return price;
	}
	var getTabbedApps = function() {
		var apps = [];
		var tab = {};
		for(var elem in $rootScope.AllApplications){
			tab = {};
			tab.title = elem;
			tab.options = [];
			for(var item in $rootScope.AllApplications[elem]) {
				tab.options.push({
					title: $rootScope.AllApplications[elem][item].title,
					icon: $rootScope.AllApplications[elem][item].icon,
					price: getAppPrice($rootScope.AllApplications[elem][item].title)
				})
			}
			apps.push(tab);			
		}
		return apps;
	}
    var config = {
        hardware: {
            'title':'Virtual Hardware',
            'options':[{
                'title':'Value Package',
                'description':'1 vCPU, 4 GB RAM, 50 GB Storage',
                id:1,
                'price':15,
                'isRequired':true
            },{
                'title':'Standard Package',
                'description':'2 vCPU, 8  GB RAM, 200 GB Storage',
                id:2,
                'price':21,
                'isRequired':true
            },{
                'title':'Advanced Package',
                'description':'4 vCPU, 16 GB RAM, 500 GB Storage',
                id:3,
                'price':29,
                'isRequired':true
            }]
        },
        os: {
            'title':'Operating System',
            'options':[{
                'title':'Windows 7',
                'price':0,
            },{
                'title':'Windows 8',
                'price':0,
            },{
                'title':'Ubuntu 14',
                'price':0,
                'isDisable':'true',
            },{
                'title':'Windows 10',
                'price':0,
                'isDisable':'true',
            }]
        },
        services: {
            'title':'Services',
            'options':[{
                'title':'Security',
                'price':1
            },{
                'title':'Backup & Restore',
                'price':1
            },{
                'title':'Web Filtering',
                'price':1,
            }]
        },
        apps: {
            'title':'Applications',
            'tabs': getTabbedApps(),

        }
    };

    var imagePath = 'layout/icons/';
    return {
        getSelectDesk: function() { return selectDesk;},
        getConfig: function() { return config;},
        getImagePath: function() { return imagePath;}
    };
});