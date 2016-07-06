require.config({
    baseUrl: "js",
    paths: {
        'angular': '.../angular.min',
        'angular-route': '.../angular-route.min',
        'angularAMD': '.../angularAMD.min'
    },
    shim: { 'angularAMD': ['angular'], 'angular-route': ['angular'] },
    deps: ['app']
});