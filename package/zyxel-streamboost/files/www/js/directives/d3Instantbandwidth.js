(function () {
  'use strict';

  angular.module('ZyXEL.directives')
    .directive('d3Instantbandwidth', ['d3', function(d3) {
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

          var detailContainer = null;
          var previousData = null;

          // define render function
          scope.render = function(data, reload){

            if (scope.enabled == false) {
              return;
            }

            var showTotalDataInsteadOfBandwidth = scope.showTotalDataInsteadOfBandwidth;

            // remove all previous items before render
            svg.selectAll("*").remove();

            if (data == null || data.length == 0) {

              svg.attr("height", 0);

              return;
            }

            var stack = d3.layout.stack(),
                xGroupMax = d3.max(data, function(d) { return showTotalDataInsteadOfBandwidth ? d.down_bytes + d.up_bytes : d.down_bps + d.up_bps; }),
                xStackMax = d3.max(data, function(d) { return showTotalDataInsteadOfBandwidth ? d.down_bytes + d.up_bytes : d.down_bps + d.up_bps; });

            var maxValueAndUnit = valueAndAbbrevAdjusted(xStackMax, "", showTotalDataInsteadOfBandwidth ? "B" : "bps");
            var divisor = divisorFromAbbrev(maxValueAndUnit.abbrev);

            var width = d3.select(iElement[0])[0][0].offsetWidth - 20,

                height = scope.data.length * 40 + 60;

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

            // console.log("showBy: " + scope.showBy + ", currentBarIndex: " + scope.currentBarIndex);

            // totalDataDescription.attr("width", 94);

            // console.log("drawing stacked bar");

            var divisorOfBarsWidth = 3;

            if (width >= 900) {
                divisorOfBarsWidth = 2;
            }

            var x = d3.scale.linear()
                .range([120, width / divisorOfBarsWidth])
                .domain([0, xStackMax]);

            var color = ["#4DCAFF", "#95E8A0", "#FFF7A6", "#FFCF71", "#F684CD", "#D169E0", "#1E9DED", "#15CF8C", "#B7DB38", "#FF9E56", "#FF7270", "#8347D6"];

            var xFormatValue = d3.format(".1f");

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
                .tickFormat(function(d){ return xFormatValue(d / divisor);});

            ///////////////////////////////////////////////
            // Axis ticks
            ///////////////////////////////////////////////
            svg.append("g")
                .attr("class", "x axis")
                .attr("transform", "translate(0," + (data.length * 40 + 10) + ")")
                .call(xAxis);

            var layer = svg.append("g")
                           .attr("class", "layer");


            var barHeight = 24;
            var pieChartX = 0;
            var barInfoToShow = null;

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
                   .attr("y", 30 + index * 40 + 5 )
                   .style("text-anchor", "end")
                   .text(scope.showBy == "application" ? data[index].nameOfFlow : data[index].deviceDescription); //data[index].deviceDescription + ", " +

              barInfo.append("rect")
                   .attr("x", x(0))
                   .attr("y", 30 + index * 40 - barHeight / 2 )
                   .attr("width", x(xStackMax) - x(0))
                   .attr("height", barHeight)
                   .attr("class", "instantBand_barOfDeviceAppBackgroundColor");

              //////////////////////////////////////////////////
              /// Start animation from previous data.
              var startingAnimationWidth = x(0);
              if (previousData != null && previousData.length > index) {
                  startingAnimationWidth = x(showTotalDataInsteadOfBandwidth ? previousData[index].down_bytes + previousData[index].up_bytes : previousData[index].down_bps + previousData[index].up_bps) - x(0);
                  if (startingAnimationWidth > x(xStackMax) - x(0) || index == 0) {
                      startingAnimationWidth = x(xStackMax) - x(0);
                  }
              }

              barInfo.append("rect")
                   .attr("x", x(0))
                   .attr("y", 30 + index * 40 - barHeight / 2 )
                   .attr("width", startingAnimationWidth)
                   .attr("height", barHeight)
                   .attr("class", "instantBand_barOfDeviceApp")
                   .transition()
                       .delay(index * 30)
                       .attr("width", x(showTotalDataInsteadOfBandwidth ? data[index].down_bytes + data[index].up_bytes : data[index].down_bps + data[index].up_bps) - x(0));

              barInfo.append("text")
                   .attr("class", "y axis")
                   .attr("x", x(xStackMax) + 5 )
                   .attr("y", 30 + index * 40 + 5)
                   .style("text-anchor", "start")
                   .text(xFormatValue((showTotalDataInsteadOfBandwidth ? data[index].down_bytes + data[index].up_bytes : data[index].down_bps + data[index].up_bps) / divisor));

              var barInfoBBox = bboxOfElement(barInfo[0][0]);

              barInfo.append("rect")
                   .attr("x", barInfoBBox.x)
                   .attr("y", barInfoBBox.y )
                   .attr("id", index)
                   .attr("width", barInfoBBox.width)
                   .attr("height", barInfoBBox.height)
                   .style("opacity", 0.0)
                   .on( 'mouseenter', function() {
                      showDetail(this, true, this.id);
                    } )
                    .on( 'mouseout', function() {
                    } )
                    .on('click', function() {
                      showDetail(this, true, this.id);
                    } );

              pieChartX = Math.max(barInfoBBox.x + barInfoBBox.width + 25, pieChartX);

              if (index == scope.currentBarIndex) {
                barInfoToShow = barInfo;
              }

            } // for (var index in data) {

            ///////////////////////////////////////////////
            // Demarcation line + Unit
            ///////////////////////////////////////////////
            layer.append("rect")
                .attr("class", "instantBand_barOfDeviceApp")
                .attr("width", x(xStackMax) - x(0))
                .attr("height", 2)
                .attr("x", x(0))
                .attr("y", data.length * 40 + 30);

            layer.append("text")
                 .attr("x", x(xStackMax / 2) )
                 .attr("y", data.length * 40 + 50)
                 .style("text-anchor", "middle")
                 .text(scope.translation.Data + "(" + maxValueAndUnit.abbrev + maxValueAndUnit.unit + ")");


            function showPie(detailInfo, svgBox, animateFanOut, dialogPoint) {
              var radius = 0;
              var hideLabelWidth = 700;
              if (svgBox.width > svgBox.height) {
                radius = svgBox.height / 2;
              }
              else {
                if (width > hideLabelWidth ) {
                  radius = (svgBox.width - 160) / 2;
                }
                else {
                  radius = (svgBox.width) / 2;
                }
              }

              var centerY = dialogPoint.y;

              if (centerY - radius < svgBox.y ) {
                centerY = radius + 5;
              }
              else if (centerY + radius > svgBox.y + svgBox.height) {
                centerY = svgBox.y + svgBox.height - radius - 5;
              }

              detailContainer.append("g")
                .attr("class", "slices").attr("transform", "translate(" + (svgBox.x + radius)  + "," + ( centerY )  + ")");
                // .attr("class", "slices").attr("transform", "translate(" + (svgBox.x + radius)  + "," + (svgBox.y + svgBox.height / 2)  + ")");

              if (width > hideLabelWidth) {
                detailContainer.append("g")
                  .attr("class", "labels").attr("transform", "translate(" + (svgBox.x + radius * 2 )  + "," + ( centerY )  + ")");
                  // .attr("class", "labels").attr("transform", "translate(" + (svgBox.x + radius * 2 )  + "," + (svgBox.y )  + ")");
              }

              var arrayOfKeys = [];
              var hashOfValues = {};

              var uploadValue = 0;
              var downloadValue = 0;

              for (var key in detailInfo) {
                arrayOfKeys.push(detailInfo[key].name);
                hashOfValues[detailInfo[key].name] = showTotalDataInsteadOfBandwidth? detailInfo[key].up_bytes + detailInfo[key].down_bytes : detailInfo[key].up_bps + detailInfo[key].down_bps;
                if (hashOfValues[detailInfo[key].name] == 0) {
                  hashOfValues[detailInfo[key].name] = 0.00001;
                }
                uploadValue += showTotalDataInsteadOfBandwidth? detailInfo[key].up_bytes : detailInfo[key].up_bps;
                downloadValue += showTotalDataInsteadOfBandwidth? detailInfo[key].down_bytes : detailInfo[key].down_bps;
              }

              detailContainer.append("text")
                .attr( 'class', 'instantBand_label_totalBandwidth' )
                .attr( 'x', svgBox.x + radius )
                .attr( 'y', centerY - 35)
                .attr( 'text-anchor', 'middle' )
                .text( scope.translation.Total + "(" + scope.translation.Bandwidth + ")");

              detailContainer.append("svg:image")
                             .attr('width', 28)
                             .attr('height', 22)
                             .attr('x', svgBox.x + radius * 0.55 )
                             .attr('y', centerY - 20)
                             .attr("xlink:href","/images/usage_monitor/icon_upload_blue_s.png");

              detailContainer.append("svg:image")
                             .attr('width', 28)
                             .attr('height', 22)
                             .attr('x', svgBox.x + radius * 0.55 )
                             .attr('y', centerY + 12)
                             .attr("xlink:href","/images/usage_monitor/icon_download_blue_s.png");

              detailContainer.append("text")
                .attr( 'class', 'instantBand_label_totalBandwidthUploadValue' )
                .attr( 'x', svgBox.x  + radius )
                .attr( 'y', centerY - 2)
                .attr( 'text-anchor', 'middle' )
                .text( xFormatValue(uploadValue / divisor) );

              detailContainer.append("text")
                .attr( 'class', 'instantBand_label_totalBandwidthUploadUnit' )
                .attr( 'x', svgBox.x  + radius * 1.45 )
                .attr( 'y', centerY - 6)
                .attr( 'text-anchor', 'end' )
                .text( maxValueAndUnit.abbrev + maxValueAndUnit.unit);

              detailContainer.append("text")
                .attr( 'class', 'instantBand_label_totalBandwidthDownloadValue' )
                .attr( 'x', svgBox.x  + radius )
                .attr( 'y', centerY + 30)
                .attr( 'text-anchor', 'middle' )
                .text( xFormatValue(downloadValue / divisor));

              detailContainer.append("text")
                .attr( 'class', 'instantBand_label_totalBandwidthDownloadUnit' )
                .attr( 'x', svgBox.x  + radius * 1.45 )
                .attr( 'y', centerY + 26)
                .attr( 'text-anchor', 'end' )
                .text( maxValueAndUnit.abbrev + maxValueAndUnit.unit);

              var pieColor = d3.scale.ordinal()
                .domain(arrayOfKeys) // ["Lorem ipsum", "dolor sit", "amet", "consectetur", "adipisicing", "elit", "sed", "do", "eiusmod", "tempor", "incididunt"]
                .range(color); // egg

              var pie = d3.layout.pie()
                .sort(null)
                .value(function(d) {
                  return d.value;
                });

              var arc = d3.svg.arc()
                .outerRadius(radius * 0.7)
                .innerRadius(radius * 0.5);

              var outerArc = d3.svg.arc()
                               .innerRadius(radius * 0.5)
                               .outerRadius(radius * 0.75);

              var key = function(d){ return d.data.label; };

              function randomData (){
                var labels = pieColor.domain();
                return labels.map(function(label){
                  return { label: label, value: hashOfValues[label] }
                });
              }

              change(randomData(), animateFanOut);

              function change(data, animateFanOut) {
                /* ------- PIE SLICES -------*/
                var slice = svg.select(".slices").selectAll("path.slice")
                  .data(pie(data), key);

                var defs = svg.append("defs");

                // black drop shadow

                var filter = defs.append("filter")
                    .attr("id", "drop-shadow")

                filter.append("feGaussianBlur")
                    .attr("in", "SourceGraphic")
                    .attr("stdDeviation", 2)
                    .attr("result", "blur");
                filter.append("feOffset")
                    .attr("in", "blur")
                    .attr("dx", 0)
                    .attr("dy", 0)
                    .attr("result", "offsetBlur");

                var feMerge = filter.append("feMerge");

                feMerge.append("feMergeNode")
                    .attr("in", "offsetBlur")
                feMerge.append("feMergeNode")
                    .attr("in", "SourceGraphic");


                slice.enter()
                  .insert("path")
                  .style("fill", function(d) { return pieColor(d.data.label); })
                  .style("filter", "url(#drop-shadow)")
                  .attr("class", "slice")
                  .on( 'mouseenter', function( d ) {
                      if (d.enableMouseEvent == false) {
                        return;
                      }
                      d3.select( this )
                         // .attr("stroke","white")
                         .transition()
                         .duration(500)
                         .attr("d", outerArc)
                         .attr("stroke-width",6);

                      var label = d3.select("#label_" + d.data.label)
                                  .attr("class", "instantBandwidth_label_focused");

                      var bbox = bboxOfElement(label[0][0]);
                      var ctm = label[0][0].getCTM();

                      var image = svg.append("svg:image")
                                     .attr("class", "instantBandwidth_label_focused_image")
                                     .attr('width', 10)
                                     .attr('height', 10)
                                     .attr('x', bbox.x - 10 - 3 )
                                     .attr('y', bbox.y)
                                     .attr("xlink:href","/images/1-circle.png");

                      setTM(image[0][0], ctm);

                      d.active = true;

                    } )
                    .on( 'mouseout', function( d ) {
                      if (d.enableMouseEvent == false) {
                        return;
                      }
                      d3.select( this )
                        .transition()
                        .attr("d", arc)
                        .attr("stroke","none");

                      d3.select("#label_" + d.data.label)
                        .attr("class", "");

                      d3.selectAll(".instantBandwidth_label_focused_image").remove();

                      d.active = false;

                    } )
                    .on('click', function( d ) {
                      if (d.enableMouseEvent == false) {
                        return;
                      }
                      d3.select( this )
                         // .attr("stroke","white")
                         .transition()
                         .duration(500)
                         .attr("d", outerArc)
                         .attr("stroke-width",6);


                      var label = d3.select("#label_" + d.data.label)
                                  .attr("class", "instantBandwidth_label_focused");

                      var bbox = bboxOfElement(label[0][0]);
                      var ctm = label[0][0].getCTM();

                      var image = svg.append("svg:image")
                                     .attr("class", "instantBandwidth_label_focused_image")
                                     .attr('width', 10)
                                     .attr('height', 10)
                                     .attr('x', bbox.x - 10 - 3 )
                                     .attr('y', bbox.y)
                                     .attr("xlink:href","/images/1-circle.png");

                      setTM(image[0][0], ctm);

                      d.active = true;
                    } );

                slice
                  .transition().duration(1000)
                  .each( function(d) {
                    d.enableMouseEvent = false;
                    if (animateFanOut)
                      this._current = { startAngle: 0, endAngle: 0 };
                  } )
                  .attrTween("d", function(d) {
                    this._current = this._current || d;
                    var interpolate = d3.interpolate(this._current, d);
                    this._current = interpolate(0);
                    return function(t) {
                      if (t == 1) {
                        d.enableMouseEvent = true;
                      }
                      return arc(interpolate(t));
                    };
                  });

                slice.exit()
                  .remove();

                // Remove circle_sliceTitleIndicator
                svg.selectAll(".circle_sliceTitleIndicator").remove();

                /* ------- TEXT LABELS -------*/

                var text = svg.select(".labels").selectAll("text")
                  .data(pie(data), key);

                text.enter()
                  .append("text")
                  .attr("dy", ".35em")
                  .attr( 'text-anchor', 'start' )
                  .attr("id", function(d) {
                    return "label_" + d.data.label;
                  })
                  .text(function(d) {
                    return d.data.label + ": " + ((d.endAngle - d.startAngle) / 2 / Math.PI * 100).toFixed(1) + "%" ;
                  });

                function midAngle(d){
                  return d.startAngle + (d.endAngle - d.startAngle)/2;
                }

                text.transition()
                    .duration(animateFanOut? 1000 : 0)
                    .attrTween("transform", function(d, i) {
                      this._current = this._current || d;
                      var interpolate = d3.interpolate(this._current, d);
                      this._current = interpolate(0);
                      return function(t) {
                        return "translate(0, "+ ( 50 + i * 20 * t - radius * 0.6) +")";
                      };
                    })
                    .each( 'end', function() {

                      var bbox = bboxOfElement(this);
                      var ctm = this.getCTM();
                      var circle = svg.append( 'circle' )
                            .attr("class", "circle_sliceTitleIndicator")
                            .attr( 'r', 5 )
                            .attr('cx', bbox.x - 5 - 3)
                            .attr('cy', bbox.y + 5)
                            .style('fill', pieColor(this.id.replace("label_","")));

                      setTM(circle[0][0], ctm);

                    } );
                    // .attr("y", function(d, i) { return 50 + i * 20; });

                text.exit()
                  .remove();

              }; // changeData

            } // function showPie()


            function showDetail(element, animated, index) {
              // console.log("showDetail, index:" + index);
              scope.currentBarIndex = index;
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
              detailContainer.append("path")
                   .attr("d", pathOfRoundRectByRect(bBox))
                   .style("fill", "gray")
                   .style("opacity", 0.2)
                   ;

              var dialogPoint = { x: pieChartX - 10, y: bBox.y + bBox.height / 2 };

              var pieChartBox = bBox;
              pieChartBox.x = pieChartX;
              pieChartBox.y = 5;
              pieChartBox.width = width - pieChartX - 5;
              pieChartBox.height = height - 5 - 5;

              detailContainer.append("path")
                   .attr("class", "bubble_tooltip bubble_tooltipInstantBandwidth")
                   .attr("d", pathOfDialogByRect(pieChartBox, dialogPoint))
                   ;

              showPie(data[element.id].detail, pieChartBox, animated, dialogPoint);

            } // showDetail(element ) {

            function hideDetail() {
              detailContainer.selectAll("*").remove();
            } // hideDetail( ) {

            detailContainer = svg.append( 'g' );

            // show first bar info
            if (barInfoToShow != null) {
              showDetail(barInfoToShow[0][0], reload, scope.currentBarIndex);
            }
            previousData = data;
          }; // scope.render = function(data){

          function pathOfDialogByRect(svgRect, dialogPoint) {
            var radius = Math.min(svgRect.width, svgRect.height) / 5;
            if (radius > 10) {
              radius = 10;
            }
            return pathOfDialogByAttributes(svgRect.x, svgRect.y, svgRect.width, svgRect.height,
                radius, dialogPoint);
          }

          function pathOfDialogByAttributes(x, y, width, height, radius, dialogPoint) {
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

          function decreaseAbbrev(abbrev) {
            switch (abbrev) {
              case "T" :
                return "G";
              case "G" :
                return "M";
              case "M" :
                return "K";
              case "K" :
                return "";
            }
            return abbrev;
          }

        function increaseAbbrev(abbrev) {
            switch (abbrev) {
              case "G" :
                return "T";
              case "Mbps" :
                return "G";
              case "K" :
                return "M";
              case "" :
                return "K";
            }
            return abbrev;
          }


          function divisorFromAbbrev(abbrev) {
            switch (abbrev) {
              case "T" :
                return 1000 * 1000 * 1000 * 1000;
              case "G" :
                return 1000 * 1000 * 1000;
              case "M" :
                return 1000 * 1000;
              case "K" :
                return 1000;
            }
            return 1;
          }

          function valueAndAbbrevAdjusted(value, abbrev, originalUnit) {
            var returnData = { value: value, unit: originalUnit, abbrev: abbrev};
            if (value == 0 || value >= 1 && value < 1000) {
              return returnData;
            }
            else if (value >= 1000) {
                var unit = originalUnit;
                do {
                  value /= 1000;
                  abbrev = increaseAbbrev(abbrev);
                } while (value > 1000);
                return {value: value, unit: originalUnit, abbrev: abbrev};
            }
            else {
                var unit = originalUnit;
                do {
                  value *= 1000;
                  abbrev = decreaseAbbrev(abbrev);
                } while (value < 1);
                return {value: value, unit: originalUnit, abbrev: abbrev};
            }
          }

          function setTM(element, m) {
              if (element == null || m == null) {
                  return null;
              }
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

          scope.closeAndDisable = function (callback) {

            if (scope.enabled == false) {
              return;
            }

            scope.enabled = false;

            var numTransitions = 0;

            var delay = 10;
            var duration = 200;

            if (scope.data == null) {
              closeSVG(callback);
              return;
            }

            if (scope.data.length > 60) {
              duration = 50;
              delay = 2;
            }
            else if (scope.data.length > 20) {
              duration = 150;
              delay = 7
            }

            svg.selectAll("rect, path").transition()
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

              svg.select(".slices").selectAll("path.slice")
                  .transition()
                  .duration(duration)
                  .delay(function(d, i) { return i * delay; })
                  .style("opacity", "0.0");

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
              return;
            }

            scope.enabled = true;
            scope.render(scope.data);

          }; // scope.openAndEnable = function () {

        } // link: function(scope, iElement, iAttrs)
      }; // .directive('d3Instantbandwidth', ['d3', function(d3) {
    }]); // angular.module('ZyXEL.directives')

}());
