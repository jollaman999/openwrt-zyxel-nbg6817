(function () {
  'use strict';

  angular.module('ZyXEL.directives')
    .directive('d3Timeusage', ['d3', function(d3) {
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
              .attr("width", "100%");

          var enabled = true;

          // on window resize, re-render d3 canvas
          window.onresize = function() {
            return scope.$apply();
          };
          scope.$watch(function(){
              return angular.element(window)[0].innerWidth;
            }, function(){
              return scope.render(scope.data);
            }
          );

          // watch for data changes and re-render
          scope.$watch('data', function(newVals, oldVals) {
            if (newVals == oldVals) {
              return;
            }
            return scope.render(newVals);
          }, true);

          var DURATION = 1500;
          var DELAY    = 500;

          var detailContainer = null;
          var circleContainer = null;
          var previousData = null;

          // define render function
          scope.render = function(data){
            if (scope.enabled == false) {
              return;
            }

            // remove all previous items before render
            svg.selectAll("*").remove();

            if (data == null || data.length == 0 || data[0].data == null) {

              svg.attr("height", 0);

              return;
            }

            // console.log("data: ");
            // console.log(data);

            var stack = d3.layout.stack(),
                xGroupMax = getMaxByShowingSelection(scope.showBy),
                xStackMax = xGroupMax;

            var width = d3.select(iElement[0])[0][0].offsetWidth - 20,

                height = data.length * 40 + 60;

            if (height < 300) {
              height = 300;
            }

            if (width < 20) {
              // console.log("width: " + width + ", ignore.");
              // console.log("body: " + $('body').width());
              width = $('body').width();
              if (width < 20) {
                return;
              }
               svg.attr("width", width)
                  .attr("height", height);
            }
            else {
              svg.attr("width", "100%")
                  .attr("height", height);
            }

            svg.append("rect")
              .attr("class", "boundingRect")
              .attr("width", "100%")
              .attr("height", "100%")
              // .attr("fill", "gray");
              .style("opacity", 0.0);


            if (xStackMax == 0) {

              var svgBoundingBox = bboxOfElement(d3.select(".boundingRect").node());

              if (svgBoundingBox.width == 0) {
                svgBoundingBox.width = width;
              }

              svg.append("text")
                  .attr( 'class', 'lineChart--bubble--dateDownload' )
                  .attr( 'x', svgBoundingBox.x + svgBoundingBox.width / 2 )
                  .attr( 'y', svgBoundingBox.y + height / 4 - 10)
                  .attr( 'text-anchor', 'middle' )
                  .text( scope.translation.LoadingPleaseWait)
                  .attr("stroke", "#000" );
              return;
            }

            var divisorOfBarsWidth = 1.7;

            if (width >= 900) {
                divisorOfBarsWidth = 1.3;
            }

            var x = d3.scale.linear()
                .range([120, width / divisorOfBarsWidth])
                .domain([0, xStackMax]);

            var color = ["#D069DE", "#41BDFE", "#84E38D", "#FEF694", "#FEC65F", "#EB66BD"];

            var xFormatValue = d3.format(".0f");

            var xAxisTickValues = [0, xStackMax / 4, xStackMax / 2, xStackMax / 4 * 3, xStackMax];

            // adjust xAxisTickInterval by number of data and width
            if (width < 400) {
                xAxisTickValues = [0, xStackMax]
            }
            else if (width <= 638) {
                xAxisTickValues = [0, xStackMax / 2, xStackMax];
            }

            var xAxis = d3.svg.axis()
                .scale(x)
                .orient("bottom")
                .tickValues(xAxisTickValues)
                .tickSize(0)
                .tickFormat(function(d){ return xFormatValue(d);});

            ///////////////////////////////////////////////
            // Axis ticks
            ///////////////////////////////////////////////
            svg.append("g")
                .attr("class", "x axis")
                .attr("transform", "translate(0," + (10) + ")")
                .call(xAxis);

            var layer = svg.append("g")
                           .attr("class", "layer");

            var barHeight = 24;
            var pieChartX = 0;
            var barInfoToShow = null;
            var marginToTop = 50;

            ///////////////////////////////////////////////
            // Demarcation line + Unit
            ///////////////////////////////////////////////
            layer.append("rect")
                .attr("class", "instantBand_barOfDeviceApp")
                .attr("width", x(xStackMax) - x(0))
                .attr("height", 2)
                .attr("x", x(0))
                .attr("y", marginToTop - 20);

            layer.append("text")
                 .attr("x", x(xStackMax) + ( xStackMax < 100 ? 10 : 20 ) )
                 .attr("y", 22)
                 .style("text-anchor", "start")
                 .text("hr" + (scope.showBy != "daily" ? "s" : ""));

            ///////////////////////////////////////////////
            // Horizontal bars
            ///////////////////////////////////////////////
            for (var index in data) {

              var barInfo = layer.append("g")
                                 .attr("id", index)
                                 .attr("class", "barInfo");

              barInfo.append("text")
                   .attr("class", "y axis")
                   .attr("x", x(0) - 5 )
                   .attr("y", marginToTop + index * 40 + 5 )
                   .style("text-anchor", "end")
                   .text(flowname(data[index].policyID));

              if (scope.showBy != "daily") {

                  ////////////////////////
                  // Append total

                  barInfo.append("rect")
                       .attr("x", x(0))
                       .attr("y", marginToTop + index * 40 - barHeight / 2 )
                       .attr("width", x(xStackMax) - x(0))
                       .attr("height", barHeight)
                       .attr("class", "instantBand_barOfDeviceAppBackgroundColor");

                   //////////////////////////////////////////////////
                   /// Start animation from previous data.
                   var startingAnimationWidth = 0;
                   if (previousData != null && previousData.length > index) {
                       startingAnimationWidth =  x(previousData[index].data.flowUpTimeNotOverlappedInMinutes / 60)  - x(0);
                       if (startingAnimationWidth > x(xStackMax) - x(0)) {
                           startingAnimationWidth = x(xStackMax) - x(0);
                       }
                   }

                  barInfo.append("rect")
                      .attr("x", x(0))
                      .attr("y", marginToTop + index * 40 - barHeight / 2 )
                      .attr("width", startingAnimationWidth)
                      .attr("height", barHeight)
                      .attr("class", "instantBand_barOfDeviceApp")
                      .transition()
                          .delay(index * 30)
                          .attr("width", x(data[index].data.flowUpTimeNotOverlappedInMinutes / 60)  - x(0));

                  ////////////////////////
                  // show total hour
                  barInfo.append("text")
                       .attr("class", "y axis")
                       .attr("x", x(xStackMax) + 5 )
                       .attr("y", marginToTop + index * 40 + 5)
                       .style("text-anchor", "start")
                       .text(xFormatValue(data[index].data.flowUpTimeNotOverlappedInMinutes < 60 ? 1 : data[index].data.flowUpTimeNotOverlappedInMinutes / 60));
              }
              else {
                    ////////////////////////
                    // show hourly block
                    var widthOfHourlyBlock = x(1) - x(0) - 3 < 0 ? 0 : x(1) - x(0) - 3;

                    var TRANSFERThresholdToShowAsActiveFlow = 1000000; // 1MByte as threashold.
                    for (var hour = 0; hour < 24; ++ hour) {
                        var prefixOfClassName = hour >= 0 && hour < 6 ? "timeusage_daily_warninghour_flow_" : "timeusage_daily_safehour_flow_";
                        var transferfedBytesInHour = 0;
                        if (data[index].data != null && data[index].data.rxHourly != null && data[index].data.rxHourly[hour] != null) {
                            transferfedBytesInHour += data[index].data.rxHourly[hour];
                        }
                        if (data[index].data != null && data[index].data.txHourly != null &&data[index].data.txHourly[hour] != null) {
                            transferfedBytesInHour += data[index].data.txHourly[hour];
                        }

                        // if (transferfedBytesInHour > 0 && transferfedBytesInHour < TRANSFERThresholdToShowAsActiveFlow) {
                        //     console.log("screen out transferfedBytesInHour(" + hour + "): " + transferfedBytesInHour);
                        // }

                        var classNameOfBlock = prefixOfClassName + ( transferfedBytesInHour >= TRANSFERThresholdToShowAsActiveFlow ? "active" : "inactive" );

                        barInfo.append("rect")
                             .attr("x", x(hour))
                             .attr("width", 0 )
                             .attr("y", marginToTop + index * 40 - barHeight / 2 )
                             .attr("height", barHeight)
                             .attr("class", classNameOfBlock)
                             .transition()
                                 .delay(index * 5 * 24 + hour * 5)
                                 .attr("width", widthOfHourlyBlock );

                    }

              }

              var barInfoBBox = {x: x(0), y: marginToTop + index * 40 - barHeight / 2 , height:barHeight, width:x(xStackMax) - x(0)} // bboxOfElement(barInfo[0][0]);

              barInfo.append("rect")
                   .attr("x", barInfoBBox.x)
                   .attr("y", barInfoBBox.y )
                   .attr("id", index)
                   .attr("width", barInfoBBox.width)
                   .attr("height", barInfoBBox.height)
                   .style("opacity", 0.0)
                //    .style("fill", "orange")
                   .on( 'mouseenter', function() {
                      showDetail(this, this.id);
                    } )
                    .on( 'mouseout', function() {
                    } )
                    .on('click', function() {
                      showDetail(this, this.id);
                    } );

              pieChartX = Math.max(barInfoBBox.x + barInfoBBox.width + 25, pieChartX);

              if (index == scope.currentBarIndex) {
                barInfoToShow = barInfo;
              }

            } // for (var index in data) {

            function getMaxByShowingSelection(value) {
                switch (value) {
                    case "daily" :
                        return 24;
                    case "weekly" :
                        return 24 * 7;
                    case "monthly" :
                        return 24 * 30;
                    default :
                        return 24 * 90;
                }
            }

            function hideDetail() {
              detailContainer.selectAll(".bubble_tooltip").remove();
            }

            function stringFormatOfDate(date) {
                var nDay    = date.getDate();
                var nMonth  = date.getMonth()+1; //January is 0!
                var nYear   = date.getFullYear();
                return  nYear + '/' + nMonth + '/' + nDay;
            }

            function setTM(element, m) {
                return element.transform.baseVal.initialize(element.ownerSVGElement.createSVGTransformFromMatrix(m));
            };

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

            function fitTextToSize(element, fitToWidth) {
              var bbox = bboxOfElement(element.node());

              if (bbox.width < fitToWidth) {
                return;
              }

              var fontSize = parseInt(element.style("font-size").replace("px", ""));

              while (fontSize > 1 && bbox.width > fitToWidth) {
                --fontSize;
                element.style("font-size", fontSize + "px");
                bbox = bboxOfElement(element.node());
              }

              // console.log("Adjust fontsize to " + fontSize);
            }

            function drawCircles( data, nodeType ) {
              if (circleContainer != null) {
                // console.log(circleContainer.selectAll("*"));
                circleContainer.selectAll("." + nodeType).remove();
                // circleContainer = null;
              }
              else {
                circleContainer = svg.append( 'g' );

                if (detailContainer != null) {
                  detailContainer = svg.append( 'g' );
                }
              }

              // console.log(data.length);
              data.forEach( function( datum, index ) {
                  drawCircle( datum, index, nodeType );
              } );
            }

            function hideCircleDetails() {
              circleContainer.selectAll( '.lineChart--bubble' )
                              .remove();
            }

            function showDetail( element, index ) {

                // console.log("showDetail, element.id:" + element.id + ", index: " + index);
                scope.currentBarIndex = element.id;
                detailContainer.selectAll("*").remove();
                var bBox = bboxOfElement(element);
                // detailContainer.append("rect")
                //      .attr("x", bBox.x - 5)
                //      .attr("y", bBox.y - 5)
                //      .attr("width", bBox.width + 10)
                //      .attr("height", bBox.height + 10)
                //      .style("fill", "orange")
                //      .style("opacity", 0.2);
                bBox.x -=5;
                bBox.y -=5;
                bBox.width +=10;
                bBox.height +=10;

                ////////////////////////
                // Draw item lightlight
                detailContainer.append("path")
                     .attr("d", pathOfRoundRectByRect(bBox))
                     .style("fill", "gray")
                     .style("opacity", 0.2)
                     ;
                 ////////////////////////
                 // Draw Dialog
                var dialogPoint = { x: pieChartX - 10, y: bBox.y + bBox.height / 2 };

                var detailBox = bBox;
                detailBox.x = pieChartX;
                detailBox.height = 150;
                detailBox.y = bBox.y - detailBox.height / 3;
                if (detailBox.y < 0) {
                    detailBox.y = 5;
                }
                else if (detailBox.y + detailBox.height > height) {
                    detailBox.y = height - detailBox.height - 5;
                }
                detailBox.width = (width - pieChartX - 5 > 130 ? 130 : width - pieChartX - 5);

                detailContainer.append("path")
                     .attr("class", "bubble_tooltip bubble_tooltipInstantBandwidth")
                     .attr("d", pathOfDialogByRect(detailBox, dialogPoint))
                     ;

                 ////////////////////////
                 // Show images & value & unit
                 var radius = Math.min(detailBox.width, detailBox.height) / 2;
                 detailContainer.append("svg:image")
                                .attr('width', 40)
                                .attr('height', 31)
                                .attr('x', detailBox.x + radius * 0.55 )
                                .attr('y', detailBox.y + radius - 50)
                                .attr("xlink:href","/images/usage_monitor/icon_upload_blue_s.png");

                 detailContainer.append("svg:image")
                                .attr('width', 40)
                                .attr('height', 31)
                                .attr('x', detailBox.x + radius * 0.55 )
                                .attr('y', detailBox.y + radius + 20)
                                .attr("xlink:href","/images/usage_monitor/icon_download_blue_s.png");

                 var item = scope.data[element.id].data;

                 if (typeof(item) != "undefined" && item != null) {
                    //  console.log(item);
                     var uploadV = valueAndUnitAdjusted(item.tx_bytes, "Byte");
                     var downloadV = valueAndUnitAdjusted(item.rx_bytes, "Byte");
                    //  console.log(uploadV);
                    //  console.log(downloadV);
                     detailContainer.append("text")
                       .attr( 'class', 'instantBand_label_totalBandwidthUploadValue' )
                       .attr( 'x', detailBox.x  + radius - 8)
                       .attr( 'y', detailBox.y + radius + 5)
                       .attr( 'text-anchor', 'middle' )
                       .text( xFormatValue(uploadV.value) );

                     detailContainer.append("text")
                       .attr( 'class', 'instantBand_label_totalBandwidthUploadUnit' )
                       .attr( 'x', detailBox.x  + radius * 1.3 )
                       .attr( 'y', detailBox.y + radius + 5 - 3)
                       .attr( 'text-anchor', 'left' )
                       .text( uploadV.unit);

                     detailContainer.append("text")
                       .attr( 'class', 'instantBand_label_totalBandwidthDownloadValue' )
                       .attr( 'x', detailBox.x  + radius - 8)
                       .attr( 'y', detailBox.y + radius + 70)
                       .attr( 'text-anchor', 'middle' )
                       .text( xFormatValue(downloadV.value));

                     detailContainer.append("text")
                       .attr( 'class', 'instantBand_label_totalBandwidthDownloadUnit' )
                       .attr( 'x', detailBox.x  + radius * 1.3 )
                       .attr( 'y', detailBox.y + radius + 70 - 3)
                       .attr( 'text-anchor', 'left' )
                       .text( downloadV.unit);
                 }


            } // showDetail

            function pathOfDialogByRect(svgRect, dialogPoint) {
              var radius = Math.min(svgRect.width, svgRect.height) / 5;
              if (radius > 10) {
                radius = 10;
              }
              return pathOfDialogByAttributes(svgRect.x, svgRect.y, svgRect.width, svgRect.height,
                  radius, dialogPoint);
            }

            function pathOfDialogByAttributes(x, y, width, height, radius, dialogPoint) {
            //   console.log("dialogPoint: ");
            //   console.log(dialogPoint);
              var dialogHeight = 20;
              return "M" + (x + radius) + "," + y +
                     "h" + (width - 2 *radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + radius + "," + radius +
                     "v" + (height - 2 * radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + -radius + "," + radius +
                     "h" + (-width + 2 * radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + -radius + "," + -radius +
                     "V" + (dialogPoint.y + dialogHeight / 2) +
                     "L" + dialogPoint.x + "," + dialogPoint.y +
                     "L" + (x) + "," + (dialogPoint.y - dialogHeight / 2) +
                     "V" + (y + radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + radius + "," + -radius +
                     "z";
              ;

            }

            function pathOfRoundRectByRect(svgRect) {
              var radius = Math.min(svgRect.width, svgRect.height) / 5;
              if (radius > 10) {
                radius = 10;
              }
              return pathOfRoundRectByAttributes(svgRect.x, svgRect.y, svgRect.width, svgRect.height,
                  radius );
            }

            function pathOfRoundRectByAttributes(x, y, width, height, radius) {

              return "M" + (x + radius) + "," + y +
                     "h" + (width - 2 * radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + radius + "," + radius +
                     "v" + (height - 2 * radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + -radius + "," + radius +
                     "h" + (-width + 2 * radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + -radius + "," + -radius +
                     "v" + (-height + 2 * radius) +
                     "a" + radius + "," + radius + " 0 0,1 " + radius + "," + -radius +
                     "z"
              ;

            }

            // Inspired by Lee Byron's test data generator.
            function bumpLayer(n, o) {
              function bump(a) {
                var x = 1 / (.1 + Math.random()),
                    y = 2 * Math.random() - .5,
                    z = 10 / (.1 + Math.random());
                for (var i = 0; i < n; i++) {
                  var w = (i / n - y) * z;
                  a[i] += x * Math.exp(-w * w);
                }
              }

              var a = [], i;
              for (i = 0; i < n; ++i) a[i] = o + o * Math.random();
              for (i = 0; i < 5; ++i) bump(a);
              return a.map(function(d, i) { return {x: i, y: Math.max(0, d)}; });

            }

            function increaseUnit(unit) {
              switch (unit) {
                case "GByte" :
                  return "TByte";
                case "MByte" :
                  return "GByte";
                case "KByte" :
                  return "MByte";
                case "Byte" :
                  return "KByte";
              }
              return "Byte";
            }

            function decreaseUnit(unit) {
              switch (unit) {
                case "TByte" :
                  return "GByte";
                case "GByte" :
                  return "MByte";
                case "MByte" :
                  return "KByte";
                case "KByte" :
                  return "Byte";
              }
              return "Byte";
            }

            function divisorFromUnit(unit) {
              switch (unit) {
                case "Tbps" :
                  return 1000 * 1000 * 1000 * 1000;
                case "Gbps" :
                  return 1000 * 1000 * 1000;
                case "Mbps" :
                  return 1000 * 1000;
                case "Kbps" :
                  return 1000;
              }
              return 1;
            }

            function valueAndUnitAdjusted(value, originalUnit) {
              var returnData = { value: value, unit: originalUnit };
              if (value == 0 || value >= 1 && value < 1000) {
                return returnData;
              }
              else if (value >= 1000) {
                  var unit = originalUnit;
                  do {
                    value /= 1000;
                    unit = increaseUnit(unit);
                  } while (value > 1000);
                  return {value: value, unit: unit};
              }
              else {
                  var unit = originalUnit;
                  do {
                    value *= 1000;
                    unit = decreaseUnit(unit);
                  } while (value < 1);
                  return {value: value, unit: unit};
              }
            }

            function maxStackWidth(originWidth) {
              var maxWidth = 24;
              if (originWidth > maxWidth) {
                return maxWidth;
              }
              return originWidth;
            }

            function offsetToCenterStack(originWidth) {
              var width = maxStackWidth(originWidth);
              if (width == originWidth) {
                return 0;
              }

              return (originWidth - width) / 2;

            }

            function tween( b, callback ) {
              return function( a ) {
                var i = d3.interpolateArray( a, b );
                return function( t ) {
                  return callback( i ( t ) );
                };
              };
            }

            detailContainer = svg.append( 'g' );
            previousData = data;
          }; // scope.render = function(data){


          scope.closeAndDisable = function (callback) {

            if (scope.enabled == false) {
              callback();
              return;
            }

            scope.enabled = false;

            var numTransitions = 0;

            var duration = 200;


            if (scope.data == null || scope.data.length == 0) {

            }
            else if (scope.data.length > 60) {
              duration = 20;
            }
            else if (scope.data.length > 20) {
              duration = 150;
            }

            var allCircles = svg.selectAll("rect");

            if (allCircles.size() == 0) {
              closeSVG(callback);
            }
            else {
              allCircles.transition()
                    .each( "start", function() {
                      numTransitions++;
                    })
                    .duration(duration)
                    .delay(function(d, i) { return i * 10; })
                    .attr("y", 0)
                    .attr("height", 0)
                    .each( "end", function() {
                        if( --numTransitions === 0 ) {
                            closeSVG(callback);
                        }
                    });
            }

            function closeSVG(callback) {

              if (scope.enabled == true) {
                callback();
                return;
              }

              svg.selectAll("*").remove();
              svg.attr("height", 0);
              callback();

            } // function closeSVG() {

          }; // scope.closeAndDisable = function () {

          scope.openAndEnable = function () {

            if (scope.enabled == true) {
              // console.log("already enabled");
              return;
            }

            // console.log("opening chart");
            scope.enabled = true;
            scope.render(scope.data);

          }; // scope.openAndEnable = function () {


        } // link: function(scope, iElement, iAttrs)
      }; // .directive('d3Timeusage', ['d3', function(d3) {
    }]); // angular.module('ZyXEL.directives')

}());
