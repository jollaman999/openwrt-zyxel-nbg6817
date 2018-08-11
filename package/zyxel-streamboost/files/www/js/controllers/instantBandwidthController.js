(function () {
  'use strict';

  angular.module('ZyXEL.controllers')
    .controller('instantBandwidthController', ['$scope', function($scope){
      $scope.title = "Instant Bandwidth Monitor";
      $scope.data = null;
      $scope.currentBarIndex = 0;
      $scope.showTotalDataInsteadOfBandwidth = false;
      $scope.translation = null; 
      $scope.showBy = null;
    }]);

}());
