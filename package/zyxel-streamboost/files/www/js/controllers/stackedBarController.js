(function () {
  'use strict';

  angular.module('ZyXEL.controllers')
    .controller('stackedBarController', ['$scope', function($scope){
      $scope.title = "Stacked Bar";
      $scope.d3Data = null;
      $scope.unit   = null;
      $scope.totalTransfer   = null;
      $scope.translation = null; 
    }]);

}());
