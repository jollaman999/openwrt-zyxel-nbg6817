(function () {
  'use strict';

  angular.module('ZyXEL.controllers')
    .controller('dataUsageAlertController', ['$scope', function($scope){
      $scope.title = "Data Usage Alert";
      $scope.data = null;
      $scope.unitDownload   = null;
      $scope.unitUpload   = null;
      $scope.initialBrushIndex = {begin:0, end:0};
      $scope.translation = null;
      $scope.showBy = null;
      $scope.dataUsageInfo = null;      
    }]);

}());
