'use strict';

angular.module('Desk', [])

    .controller('selectDeskController', function ($scope,Page, $rootScope, $location, $http, ConfigDesk) {
    $rootScope.compactWidthPage =false;
    Page.setTitle('Select Your Student Profile or Build Your own Application Package');
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
            command: 'newUser',
            username:$rootScope.globals.currentUser.username,
            config:$scope.selectedDesktop
        };
        var config = {
            headers : {
                'Content-Type': 'application/json'
            }
        }
        $http.get('api.json', data, config)
            .then(function successCallback(response) {
            $rootScope.isAccessDesk =true;
            // set data to access page
            $rootScope.accessData = {
                username: 'User',
                password: 'Password',
                email: 'user@ericom.com',
                url: 'https://an.ericom.com/daas.htm?username=demo21?password=Ericom123$&autostart=true',
            };
            $location.path('/access');
        }, function errorCallback(response) {
            $scope.dataLoading = false;
            // error
        });   
    };
})

    .controller('buildDeskController', function ($scope, Page, $rootScope, $location, $http, ConfigDesk) {
    $rootScope.compactWidthPage =false;
    Page.setTitle('Build you own Package of applicatons');

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
            command: 'newUser',
            username:$rootScope.globals.currentUser.username,
            config:$scope.selectedConfig
        };
        var config = {
            headers : {
                'Content-Type': 'application/json'
            }
        }
        $http.get('api.json', data, config)
            .then(function successCallback(response) {
            $rootScope.isAccessDesk =true;
            // set data to access page
            $rootScope.accessData = {
                username: 'XXX',
                password: 'XXX',
                email: 'XXX@XXX.com',
                url: 'https://an.ericom.com/daas.htm?username=demo21?password=Ericom123$&autostart=true',
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

    .factory('ConfigDesk', function($route,$location,$rootScope){
    var selectDesk = [{
        id:1,
        title:'Health Students',   
        description:'BA , MA, PhD',   
        price:'19',   
        price_term:'month',   
        icon:'d-ic-1.png' , 
        hardware:['1 vCPU','4  GB RAM','50 GB Storage'],  
        apps:[{
            title:'Chrome', icon:'chrome.png' 
        },{
            title:'Acrobat Reader', icon:'acrobat.png' 
        },{
            title:'Outlook 2013', icon:'outlook.svg' 
        }]  
    },{
        id:2,
        title:'Education Students',   
        description:'MA, BA',   
        price:'32',   
        price_term:'month',   
        icon:'d-ic-2.png' , 
        hardware:['2 vCPU','8 GB RAM','200 GB Storage'],  
        apps:[{
            title:'Chrome', icon:'chrome.png' 
        },{
            title:'Acrobat Reader', icon:'acrobat.png' 
        },{
            title:'MC Office 2013', icon:'mc-office.svg' 
        },{
            title:'SAP', icon:'sap.png' 
        }]  
    },{
        id:3,
        title:'Economics Students',   
        description:'BA, MBA, Executive MBA, PhD',   
        price:'45',   
        price_term:'month',   
        icon:'d-ic-3.png' , 
        hardware:['4 vCPU','16 GB RAM','500 GB Storage'],  
        apps:[{
            title:'Chrome', icon:'chrome.png' 
        },{
            title:'Acrobat Reader', icon:'acrobat.png' 
        },{
            title:'MC Office 2013', icon:'mc-office.svg' 
        },{
            title:'Salesforce', icon:'salesfors.png' 
        },{
            title:'SAP', icon:'sap.png' 
        }]  
    }];
    var config = {
        hardware: {
            'title':'Virtual Hardware',
            'options':[{
                'title':'Value Package',
                'description':'1 vCPU, 4 GB RAM, 50 GB Storage',
                id:1,
                'price':19,
                'isRequired':true
            },{
                'title':'Standard Package',
                'description':'2 vCPU, 8  GB RAM, 200 GB Storage',
                id:2,
                'price':32,
                'isRequired':true
            },{
                'title':'Advanced Package',
                'description':'4 vCPU, 16 GB RAM, 500 GB Storage',
                id:3,
                'price':45,
                'isRequired':true
            }]
        },
        os: {
            'title':'Operating System',
            'options':[{
                'title':'Windows 7',
                'price':2,
            },{
                'title':'Windows 8',
                'price':10,
            },{
                'title':'Ubuntu 14',
                'price':1500,
                'isDisable':'true',
            }]
        },
        services: {
            'title':'Services',
            'options':[{
                'title':'Security',
                'price':7
            },{
                'title':'Backup & Restore',
                'price':7
            },{
                'title':'Web Filtering',
                'price':7,
            }]
        },
        apps: {
            'title':'Applications',
            'tabs':[
                {
                    title : 'Health',
                    options :[{
                        title :'Microsoft Office 2013',
                        icon :'mc-office.svg',
                        price :  1
                    },{
                        title :'Word 2013',
                        icon :'mc-word.svg',
                        price : 10
                    },{
                        title :'Outlook 2013',
                        icon :'outlook.svg',
                        price : 10
                    },{
                        title :'Exel 2013',
                        icon :'exel.svg',
                        price : 10
                    },{
                        title :'PPT 2013',
                        icon :'powepoint.svg',
                        price : 10
                    },{
                        title :'NXl 2013',
                        icon :'nvc.svg',
                        price : 10
                    },{
                        title :'Access 2013',
                        icon :'access.svg',
                        price : 10
                    },{
                        title :'Access 2013',
                        icon :'access.svg',
                        price : 10,
                        isDisable: true,
                    }]
                },{
                    title : 'Education',
                    options :[{
                        title :'Microsoft Office 2015',
                        icon :'mc-office.svg',
                        price :2
                    }]
                },{
                    title : 'Economics',
                    options :[{
                        title :'Whatever',
                        icon :'mc-office.svg',
                        price :2
                    },{
                        title :'test',
                        icon :'mc-office.svg',
                        price :2
                    }]
                }
            ],

        }
    };
    var imagePath = 'layout/icons/';
    return {
        getSelectDesk: function() { return selectDesk;},
        getConfig: function() { return config;},
        getImagePath: function() { return imagePath;}
    };
});