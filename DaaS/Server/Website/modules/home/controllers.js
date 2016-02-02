'use strict';

angular.module('Desk', [])

    .controller('selectDeskController', function ($scope,Page, $rootScope, $location, $http, ConfigDesk) {
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

    .controller('buildDeskController', function ($scope, Page, $rootScope, $location, $http, ConfigDesk) {
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
            command: 'newUser',
            username:$rootScope.globals.currentUser.username,
            config:$scope.selectedConfig
        };
        var config = {
            headers : {
                'Content-Type': 'application/json'
            }
        }
        $http.post('api.json', data, config)
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

    .factory('ConfigDesk', function($route,$location,$rootScope){
    var selectDesk = [{
        id:1,
        title:'Task Workers',   
        description:'Helpdesk, Call Center, Operation',   
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
        title:'Knowledge Workers',   
        description:'Marketing, Finance, Administration',   
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
        title:'Mobile Workers',   
        description:'Sales, Field Engineers, Executives',   
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
            'tabs':[
                {
                    title : 'Office',
                    options :[{
                        title :'Microsoft Office 2013',
                        icon :'mc-office.svg',
                        price :  9
                    },{
                        title :'Outlook',
                        icon :'outlook.svg',
                        price : 2
                    },{
                        title :'Word',
                        icon :'mc-word.svg',
                        price : 2
                    },{
                        title :'PowerPoint',
                        icon :'powepoint.svg',
                        price : 2
                    },{
                        title :'Excel',
                        icon :'exel.svg',
                        price : 2
                    },{
                        title :'OneNote',
                        icon :'nvc.svg',
                        price : 2
                    },{
                        title :'Access',
                        icon :'access.svg',
                        price : 2
                    }]
                },{
                    title : 'Intenet',
                    options :[{
                        title :'Internet Explorer',
                        icon :'internet_explorer.png',
                        price :0
                    },{
                        title :'Google Chrome',
                        icon :'chrome.png',
                        price :0
                    },{
                        title :'Mozilla Firefox',
                        icon :'firefox.png',
                        price :0
                    },{
                        title :'Acrobat Reader',
                        icon :'acrobat.png',
                        price :0
                    },{
                        title :'7-zip',
                        icon :'7zip.png',
                        price :0
                    },{
                        title :'ESET Antivirus',
                        icon :'eset.png',
                        price :3
                    }]
                },{
                    title : 'Multimedia',
                    options :[{
                        title :'MovieMaker',
                        icon :'moviemaker.png',
                        price :0
                    },{
                        title :'VLC Media Player',
                        icon :'vlc.png',
                        price :0
                    },{
                        title :'KODI ',
                        icon :'kodi.png',
                        price :0
                    },{
                        title :'Picasa',
                        icon :'picasa.png',
                        price :0
                    },{
                        title :'Paint',
                        icon :'paint.png',
                        price :0
                    },{
                        title :'Camtasia Studio',
                        icon :'camtasia.png',
                        price :8
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