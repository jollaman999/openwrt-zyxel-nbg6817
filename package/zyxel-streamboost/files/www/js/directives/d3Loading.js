(function () {
  'use strict';

  angular.module('ZyXEL.directives')
    .directive('d3Loading', ['d3', function(d3) {
      return {
        restrict: 'EA',
        scope: {
          data: "=",
          label: "@",
          onClick: "&"
        },
        link: function(scope, iElement, iAttrs) {

          var svg = d3.select(iElement[0])
              .append("svg")
              .style("position", "fixed")
              .attr("width", "100%")
              .attr("height", "100%");

          var enabled = true;

          // on window resize, re-render d3 canvas
          window.onresize = function() {            
            return scope.$apply();
          };

          scope.$watch(function(){
              return angular.element(window)[0].innerWidth;
            }, function(){
              // console.log("innerWidth changed!");
              return scope.render();
            }
          );

          scope.$watch(function(){
              return angular.element(window)[0].innerHeight;
            }, function(){
              // console.log("innerHeight changed!");
              return scope.render();
            }
          );          

          var detailContainer = null;
          var boundingBox = null;

          // define render function
          scope.render = function(){

            if (scope.enabled == false) {
              return;
            }

            // remove all previous items before render
            svg.selectAll(".removeable").remove();

            ///////////////////////////////////////////////
            // Loading elements
            ///////////////////////////////////////////////

            if (boundingBox == null) {

              boundingBox = svg.append("rect")
                              .attr("class", "boundingRect")
                              .attr("width", "100%")
                              .attr("height", "100%")
                              .style("opacity", 0.0)
                              ; 
            }

            var svgBoundingBox = bboxOfElement(d3.select(".boundingRect").node());                   

            // console.log("boundingBox: ");
            // console.log("svgBoundingBox: " + svgBoundingBox.x + ", " + svgBoundingBox.y + ", " + svgBoundingBox.width + ", " + svgBoundingBox.height);

            var width = svgBoundingBox.width;
            var height = svgBoundingBox.height;

            // console.log("(W,H): (" + width + ", " + height + ")");

            // svg.append("text")
            //    .attr("class", "removeable")
            //    .attr("x", width / 2 )
            //    .attr("y", height / 2 )
            //    .style("text-anchor", "middle")
            //    .text("Loading...");  

            var boxSize = 50;

            var boxMargin = 10;

            var rectBoxTL = { x: width / 2 - boxSize - boxMargin / 2, 
                              y: height / 3 - boxSize - boxMargin / 2,
                              width: boxSize, 
                              height: boxSize};

            var rectBoxTR = { x: rectBoxTL.x + boxSize + boxMargin, 
                              y: rectBoxTL.y,
                              width: boxSize, 
                              height: boxSize};

            var rectBoxBL = { x: rectBoxTL.x, 
                              y: rectBoxTL.y + boxSize + boxMargin,
                              width: boxSize, 
                              height: boxSize};

            var rectBoxBR = { x: rectBoxBL.x + boxSize + boxMargin, 
                              y: rectBoxBL.y,
                              width: boxSize, 
                              height: boxSize};                           

            var loadingBoxes = [rectBoxTL, rectBoxTR, rectBoxBR, rectBoxBL ];

            // svg.append("rect")
            //   .attr("class", "removeable loadingBox")
            //   .attr("width", rectBoxTL.width)
            //   .attr("height", rectBoxTL.height)
            //   .attr("x", rectBoxTL.x)
            //   .attr("y", rectBoxTL.y)
            //   .attr("fill", "red");                  

            // svg.append("rect")
            //   .attr("class", "removeable loadingBox")
            //   .attr("width", rectBoxTR.width)
            //   .attr("height", rectBoxTR.height)
            //   .attr("x", rectBoxTR.x)
            //   .attr("y", rectBoxTR.y)
            //   .attr("fill", "red");

            // svg.append("rect")
            //   .attr("class", "removeable loadingBox")
            //   .attr("width", rectBoxBL.width)
            //   .attr("height", rectBoxBL.height)
            //   .attr("x", rectBoxBL.x)
            //   .attr("y", rectBoxBL.y)
            //   .attr("fill", "red");

            // svg.append("rect")
            //   .attr("class", "removeable loadingBox")
            //   .attr("width", rectBoxBR.width)
            //   .attr("height", rectBoxBR.height)
            //   .attr("x", rectBoxBR.x)
            //   .attr("y", rectBoxBR.y)
            //   .attr("fill", "red");           

            svg.selectAll(".loadingBox")
                 .data(loadingBoxes)
                 .enter().append("rect")
                    .attr("class", "removeable loadingBox")
                    .style("fill", "#d6f351")
                    .attr("x", function(d) { return d.x; })
                    .attr("y", function(d) { return d.y; })
                    // .attr("transform", function(d) { return "translate("+ d.x + ", " + d.y + ")"; })
                    .attr("width", boxSize)
                    .attr("height", boxSize)
                 .transition()
                   .delay(function(d, i) { return i % 2 == 0 ? 200 : 0 ; })
                   .each(slide);                               
                ;

            function slide() {
              var rect = d3.select(this);
              // console.log(rect);
              (function repeat() {
                rect = rect.transition()
                           .duration(300)
                           .style("opacity", 0.5)
                           .style("fill", "#79e47c")
                        .transition()
                           .duration(300)
                           .attr("width", 0)
                           .attr("transform", function(d) { return "translate("+ (d.width / 2) + ", 0)"; })
                        .transition()
                           .duration(300)
                           .attr("width", function(d) { return d.width; })
                           .attr("transform", "translate(0, 0)")
                          // .ease("linear")
                          // .attrTween("transform", function(d) {
                          //   return d3.interpolateString("translate("+ (0 )  + ", " + (0 ) + ")rotate(0)", 
                          //                               "translate("+ (0)  + ", " + (0 ) + ")rotate(360)");
                          // })
                          // .attr("x", 0)
                        .transition()
                           .duration(300)
                           .style("opacity", 1)
                           .style("fill", "#d6f351")
                        .each("end", repeat);
              })();
            }

            detailContainer = svg.append( 'g' )
                                 .attr("class", "removeable");              
          }; // scope.render = function(data){

          function bboxOfElement(node) {
            var result = {x: 0, y: 0 , height:0, width:0};
            do {
              try {
                 var bbox = node.getBBox();
                 result = {x:bbox.x, y:bbox.y , height:bbox.height, width:bbox.width};
              } 
              catch(e) {                  
              }
            } while (0);

            return result;
          } // function bboxOfElement(element) {

          scope.closeAndDisable = function (callback) {

            if (scope.enabled == false) {
              callback();
              return;
            }

            scope.enabled = false;

            var numTransitions = 0;

            var delay = 10;
            var duration = 200;

            svg.selectAll(".removeable").transition()
                  .each( "start", function() {
                    numTransitions++;
                  })
                  .duration(duration)
                  .delay(function(d, i) { return i * delay; })
                  .attr("y", 0)
                  .attr("height", 0)
                  .each( "end", function() {
                      if( --numTransitions === 0 ) {
                          closeSVG(callback);
                      }
                  });

            // set timeout to perform closeSVG just in case
            setTimeout(function() {
              if (numTransitions > 0) {
                console.log("numTransitions: "+ numTransitions +", force to closeSVG with callback");
                numTransitions = 0;
                closeSVG(callback);
              }
            }, 2000);            

            function closeSVG(callback) {

              if (scope.enabled == true) {
                callback();
                return;
              }

              svg.selectAll(".removeable").remove();
              svg.attr("height", 0);

              // console.log("closed loading, perform callback");

              callback();

            } // function closeSVG() {

          }; // scope.closeAndDisable = function () {

          scope.openAndEnable = function () {

            if (scope.enabled == true) {
              return;
            }

            scope.enabled = true;

            svg.style("position", "fixed")
                .attr("width", "100%")
                .attr("height", "100%");

            console.log("open loading");

            scope.render();

          }; // scope.openAndEnable = function () {

        } // link: function(scope, iElement, iAttrs)
      }; // .directive('d3Stackedbars', ['d3', function(d3) {
    }]); // angular.module('ZyXEL.directives')

}());
