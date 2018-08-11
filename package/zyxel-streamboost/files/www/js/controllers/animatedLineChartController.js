(function () {
  'use strict';

  angular.module('ZyXEL.controllers')
    .controller('animatedLineChartController', ['$scope', function($scope){
      $scope.title = "Animated Line Chart";
      $scope.d3Data = null;
      $scope.unitDownload   = null;
      $scope.unitUpload   = null;
      $scope.initialBrushIndex = {begin:0, end:0};
      $scope.totalTransfer   = null;
      $scope.translation = null;
    }]);

}());
