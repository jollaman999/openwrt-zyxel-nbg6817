(function () {
  'use strict';

  // create the angular app
  angular.module('ZyXEL', [
    'ZyXEL.controllers',
    'ZyXEL.directives',
    // 'ui.bootstrap'
    ]);

  // setup dependency injection
  angular.module('d3', []);
  angular.module('ZyXEL.controllers', []);
  angular.module('ZyXEL.directives', ['d3']);


}());