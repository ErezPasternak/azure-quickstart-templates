angular.module('starter.services', [])

.factory('connectionListService', function() {
  connections = [];
  return {
    getConnectionList: function(){
      return connections;
    }
  }
})

.factory("connectionService", function() {
    var observerCallbacks = [];
    var connections;
 
    var notifyObservers = function(){
        angular.forEach(observerCallbacks, function(callback){
            callback();
        });
    };
 
    return {
        registerObserverCallback: function(callback){
            observerCallbacks.push(callback);
        },
 
        getConnections: function() {
            return connections;
        },
 
        setConnection: function(value) {
            connections = value;
            notifyObservers();
        }
    }
})

.factory("userService", function($http, connectionService,$rootScope) {
    var observerCallbacks = [];
    var user = null;
 
    var notifyObservers = function(){
        angular.forEach(observerCallbacks, function(callback){
            callback();
        });
    };

    var XML_CHAR_MAP = {
        '<': '&lt;',
        '>': '&gt;',
        '&': '&amp;',
        '"': '&quot;',
        "'": '&apos;'
    };

    function escapeXml(s) {
        return s.replace(/[<>&"']/g, function (ch) {
            return XML_CHAR_MAP[ch];
        });
    }
 
    return {
        registerObserverCallback: function(callback){
            observerCallbacks.push(callback);
        },
 
        loggedInUser: function() {
            return user;
        },

        login : function(server, username, password) {

            var postData = '<Request OSUserName="' + escapeXml(username) +
                            '" Domain="" LocalDeviceId="00:00:00:00:00:00" Password="' + escapeXml(password) +
                            '" ClientUUID="" MachineName="' + window.location.hostname +
                            '" User="' + escapeXml(username) + '" LoginTicket="" StrForLogging="AccessPortal ver 7.6.0.9375 on '
                            + window.navigator.appVersion + ', ' + window.navigator.platform + '" Version="7.6.0.9375" OSName="' +
                            window.navigator.appVersion +
                            '" RemoteAddress="localhost:8011"> <AuthenticationFormRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><IterationCounter>1</IterationCounter><LanguageId>' + localStorage.getItem('lang') + '</LanguageId><LayerName xsi:nil="true" /><Mode>GET_FIRST_FORM</Mode><MultiStepId xsi:nil="true" /><RequestId>8428-&gt;1</RequestId><RequestPath /><StepName xsi:nil="true" /><TenantId /><Values><Value><Hidden>false</Hidden><Text>' + escapeXml(username) + '</Text></Value><Value><Hidden>true</Hidden><Text>' + escapeXml(password) + '</Text></Value></Values><Version>0</Version></AuthenticationFormRequest></Request>';

            return $http({
                url: server + "/EricomXML/Authentication.aspx",
                method: "POST",
                data: postData,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {

                // var response = JSON.parse(xml2json(parseXml(data),"").split("@").join("").split("#").join("").split("/").join("%2F").split("\\").join("%5C"));
 
            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });
 
 
        },


        loginCheck: function (server) {

            var postData = '<Request />';

            return $http({
                url: server + '/EricomXML/ConnectionList.aspx',
                method: "POST",
                data: postData,
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            }).success(function (data, status, headers, config) {

            }).error(function (data, status, headers, config) {
                console.log("KeepAlive failed!");
            });

        },
 
        changePassword : function(server,old,newpass,repass,user,key,layerName,multiStepId,stepName) {
            var postData = '<Request><AuthenticationFormRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><IterationCounter>2</IterationCounter><LanguageId>' + localStorage.getItem('lang') + '</LanguageId><LayerName>AD</LayerName><Mode>GET_NEXT_FORM</Mode><MultiStepId>caa0fcc7-6afa-4b88-b679-60e3ea03aec6</MultiStepId><RequestId>251564-&gt;2</RequestId><RequestPath /><StepName>MUST_CHANGE_PASSWORD</StepName><TenantId /><Values><Value><Hidden>true</Hidden><Text>' + old + '</Text></Value><Value><Hidden>true</Hidden><Text>' + newpass + '</Text></Value><Value><Hidden>true</Hidden><Text>' + repass + '</Text></Value><Value><Hidden>false</Hidden><Text>' + user + '</Text></Value><Value><Hidden>false</Hidden><Text /></Value><Value><Hidden>false</Hidden><Text>' + key + '</Text></Value></Values><Version>0</Version></AuthenticationFormRequest></Request>';

            return $http({
                url: server + "/EricomXML/Authentication.aspx",
                method: "POST",
                data: postData,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {
                
                // var response = JSON.parse(xml2json(parseXml(data),"").split("@").join("").split("#").join("").split("/").join("%2F").split("\\").join("%5C"));
 
            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });
        },

        passSkip: function (server, user, pass, key) {
            var postData = '<Request><AuthenticationFormRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><IterationCounter>2</IterationCounter><LanguageId>' + localStorage.getItem('lang') + '</LanguageId><LayerName>AD</LayerName><Mode>SKIP_TO_NEXT_FORM</Mode><MultiStepId>87af244c-7ff9-46f6-a41b-0c9715381c0a</MultiStepId><RequestId>5528-&gt;1</RequestId><RequestPath /><StepName>OPTIONAL_CHANGE_PASSWORD</StepName><TenantId /><Values><Value><Hidden>false</Hidden><Text /></Value><Value><Hidden>false</Hidden><Text /></Value><Value><Hidden>false</Hidden><Text /></Value><Value><Hidden>false</Hidden><Text>' + user + '</Text></Value><Value><Hidden>false</Hidden><Text>' + pass + '</Text></Value><Value><Hidden>false</Hidden><Text>' + key + '</Text></Value></Values><Version>0</Version></AuthenticationFormRequest></Request>';

            return $http({
                url: server + "/EricomXML/Authentication.aspx",
                method: "POST",
                data: postData,
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            }).success(function (data, status, headers, config) {

                // var response = JSON.parse(xml2json(parseXml(data),"").split("@").join("").split("#").join("").split("/").join("%2F").split("\\").join("%5C"));

            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });
        },

        radiusLogin: function (server, msId, code, user, key, layerName, multiStepId, stepName) {

            var postData = '<Request><AuthenticationFormRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><IterationCounter>2</IterationCounter><LanguageId>' + localStorage.getItem('lang') + '</LanguageId><LayerName>RADIUS</LayerName><Mode>GET_NEXT_FORM</Mode><MultiStepId>'+ msId+'</MultiStepId><RequestId>251564-&gt;2</RequestId><RequestPath /><StepName>RADIUS_LOGIN</StepName><TenantId /><Values><Value><Hidden>true</Hidden><Text>' + code + '</Text></Value><Value><Hidden>false</Hidden><Text></Text></Value><Value><Hidden>false</Hidden><Text></Text></Value><Value><Hidden>false</Hidden><Text>' + user + '</Text></Value><Value><Hidden>false</Hidden><Text /></Value><Value><Hidden>false</Hidden><Text>' + key + '</Text></Value></Values><Version>0</Version></AuthenticationFormRequest></Request>';

            return $http({
                url: server + "/EricomXML/Authentication.aspx",
                method: "POST",
                data: postData,
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            }).success(function (data, status, headers, config) {

                // var response = JSON.parse(xml2json(parseXml(data),"").split("@").join("").split("#").join("").split("/").join("%2F").split("\\").join("%5C"));

            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });
        },

        logout : function() {
            Connection.setConnection(null);
            user = null;
            notifyObservers();
        },


        // app launch 

        app_launch : function(server,application,appname) {
            var postData = '<Request ConnectionID="' + application + '" />';
            
            return $http({
                url: server + '/EricomXML/Launch.aspx',
                method: "POST",
                data: postData,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {

                // var response = JSON.parse(xml2json(parseXml(data.data),"").split("@").join("").split("#").join("").split("/").join("%2F").split("\\").join("%5C"));

                // console.log(response);
 
            }).error(function (data, status, headers, config) {
                $rootScope.serverDown();
            });            
 
 
        },


        // keep alive 

        // <Request />
 
        // Response –
        // <Response SessionIsClose="False" Status="0" MessageID="0" DefultMessage="" AlternateAddress="">
        //     <Data KeepAliveFrequency="60" RootFolder="\" HomeFolder="\">
        //         <ConnectionsList>
        //             <Connection ClientTypeId="15" Description="" DisplayName="calc" DisplayPath="calc" ExternVarNames="" IsDirectory="False" Name="calc">
        //                 <Icon Length="2648">CDATA[…]]></Icon>           
        // </Connection>
        //         </ConnectionsList>
        //     </Data>
        // </Response>

        keepAlive: function (server) {

            var postData = '<Request />';

            return $http({
                url: server + '/EricomXML/KeepAlive.aspx',
                method: "POST",
                data: postData,
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            }).success(function (data, status, headers, config) {

            }).error(function (data, status, headers, config) {
                console.log("KeepAlive failed!");
                $rootScope.serverDown();
            });
 
        },

        // logout

        // <Request />
        
        closeConnections: function (server) {

            var postData = '<Request />';

            return $http({
                url: server + '/EricomXML/Logout.aspx',
                method: "POST",
                data: postData,
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            }).success(function (data, status, headers, config) {

            }).error(function (data, status, headers, config) {
                console.error("Cannot close connections!");
            });
 
        },

        getUserSettings:function(params){

            return $http({
                url: params.server + "/EricomXML/GetUserSettings.aspx",
                method: "POST",
                data:"<Request />",
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {

            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });

        },
        setUserSettings:function(params){

            var postData = '<Request>';
                postData += '<Settings>';
                    postData += '<Favorites>';

            angular.forEach(params.favorites, function(e,i){
                postData += '<Favorite>';
                postData += escapeXml(e.Name);
                postData += '</Favorite>';
            });

                    postData += '</Favorites>';
                postData += '</Settings>';
            postData += '</Request>';

            return $http({
                url: params.server + "/EricomXML/SetUserSettings.aspx",
                method: "POST",
                data: postData,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {

            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });

        }

    };
}).factory('translationService', function($http){
    return {
        getAvailableLanguages:function(params){

            return $http({
                url: params.server + "/EricomXML/GetUserSettings.aspx",
                method: "POST",
                data:"<Request/>",
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {

            }).error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });

        },
        getStringTable:function(params){

            return $http({
                url: params.server + "/EricomXML/GetStringTable",
                method: "GET",
                params:{languageId:params.languageId},
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).success(function (data, status, headers, config) {

            })/*.error(function (data, status, headers, config) {
                console.log("AJAX failed!");
            });*/

        }
    }
});