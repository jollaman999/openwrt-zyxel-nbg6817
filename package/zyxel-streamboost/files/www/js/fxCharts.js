/*
 * Copyright (c) 2014 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary
 */

// Global Variables
var g_MaximumDaysToKeepFlowData = 91;
var g_RangeDaysOfPrecalculatedFlowData = 1;


function initGlobalVariables() {
    var retRetireOzker = retireOzker();
    console.log( 'retRetireOzker result:' + retRetireOzker);

    var numbersOfFlowEvents = getNumbersOfFlowEvents();
    g_nTotalEventFlows = numbersOfFlowEvents.numOfCurrentEventFlows;
    g_nTotalPreCalculatedFlows = numbersOfFlowEvents.numOfPreCalculatedFlows;
    g_nRemainingEventFlows = g_nTotalEventFlows;

    console.log( 'Number of total event flows:' + g_nTotalEventFlows);
    console.log( 'Number of preCalculated flows:' + g_nTotalPreCalculatedFlows);
}

function getOldestTimestampInData(data) {

    var timeStamp = zeroHourOfTimestamp(getCurrentTimestamp());

    if (data == null) {
        return timeStamp;
    }
    for (var x in data) {
        if (timeStamp > data[x].startTimestamp) {
            timeStamp = data[x].startTimestamp;
        }
    }
    return timeStamp;
}

function indexOfStartTimestampInData(data, timestamp) {

    if (data == null) {
        return 0;
    }
    for (var x in data) {
        if (timestamp == data[x].startTimestamp) {
            return x;
        }
    }
    return 0;
}

function utcTimeStampFromStringOfDate(stringOfDate) {

    if (stringOfDate == null) {
        return 0;
    }

    var replacedStringOfDate = stringOfDate.replace(/\//g, '-');

    var date = new Date(replacedStringOfDate);

    // safari fix
    if (date == "Invalid Date") {
        date = new Date(replacedStringOfDate.replace(/-/g, '/'));
    }

    return parseInt(date.getTime() / 1000) - date.getTimezoneOffset() * 60;

}

function uidIndexInFlowData(uid, flowData) {

    if (uid == "" || uid == null || flowData == null ) {
        return -1;
    }

    for (var index in flowData) {
        if (flowData[index].uid == uid) {
            return index;
        }
    }

    return -1;
}

function calculateBPS(originalByte, currentByte, originalEpoch, currentEpoch) {
    if (originalByte >= currentByte || originalEpoch >= currentEpoch) {
        return 0;
    }

    return (currentByte - originalByte) / (currentEpoch - originalEpoch) * 8;

}

function instantInfoByDevApp(flowData, showBy, sortByData) {
    var hashData = {};

    for (var index in flowData) {
        var flowOfDevice = flowData[index];
        if (showBy == "device") {
            if (typeof hashData[flowOfDevice.mac] == "undefined") {
                hashData[flowOfDevice.mac] = {};
                hashData[flowOfDevice.mac].up_bytes = 0;
                hashData[flowOfDevice.mac].down_bytes = 0;
                hashData[flowOfDevice.mac].deviceDescription = flowOfDevice.deviceDescription;
                hashData[flowOfDevice.mac].detail = {};
                hashData[flowOfDevice.mac].up_bps = 0;
                hashData[flowOfDevice.mac].down_bps = 0;
            }
            hashData[flowOfDevice.mac].up_bytes += flowOfDevice.up_bytes;
            hashData[flowOfDevice.mac].down_bytes += flowOfDevice.down_bytes;
            hashData[flowOfDevice.mac].up_bps += flowOfDevice.up_bps;
            hashData[flowOfDevice.mac].down_bps += flowOfDevice.down_bps;

            if (typeof hashData[flowOfDevice.mac].detail[flowOfDevice.name] == "undefined") {
                hashData[flowOfDevice.mac].detail[flowOfDevice.name] = {};
                hashData[flowOfDevice.mac].detail[flowOfDevice.name].up_bytes = 0;
                hashData[flowOfDevice.mac].detail[flowOfDevice.name].down_bytes = 0;
                hashData[flowOfDevice.mac].detail[flowOfDevice.name].up_bps = 0;
                hashData[flowOfDevice.mac].detail[flowOfDevice.name].down_bps = 0;
                hashData[flowOfDevice.mac].detail[flowOfDevice.name].name = flowOfDevice.nameOfFlow;
            }

            hashData[flowOfDevice.mac].detail[flowOfDevice.name].up_bytes += flowOfDevice.up_bytes;
            hashData[flowOfDevice.mac].detail[flowOfDevice.name].down_bytes += flowOfDevice.down_bytes;
            hashData[flowOfDevice.mac].detail[flowOfDevice.name].up_bps += flowOfDevice.up_bps;
            hashData[flowOfDevice.mac].detail[flowOfDevice.name].down_bps += flowOfDevice.down_bps;

        } // if (showBy == "device")
        else if (showBy == "application") {

            if (typeof hashData[flowOfDevice.name] == "undefined") {
                hashData[flowOfDevice.name] = {};
                hashData[flowOfDevice.name].up_bytes = 0;
                hashData[flowOfDevice.name].down_bytes = 0;
                hashData[flowOfDevice.name].up_bps = 0;
                hashData[flowOfDevice.name].down_bps = 0;
                hashData[flowOfDevice.name].nameOfFlow = flowOfDevice.nameOfFlow;
                hashData[flowOfDevice.name].detail = {};
            }
            hashData[flowOfDevice.name].up_bytes += flowOfDevice.up_bytes;
            hashData[flowOfDevice.name].down_bytes += flowOfDevice.down_bytes;
            hashData[flowOfDevice.name].up_bps += flowOfDevice.up_bps;
            hashData[flowOfDevice.name].down_bps += flowOfDevice.down_bps;

            if (typeof hashData[flowOfDevice.name].detail[flowOfDevice.mac] == "undefined") {
                hashData[flowOfDevice.name].detail[flowOfDevice.mac] = {};
                hashData[flowOfDevice.name].detail[flowOfDevice.mac].up_bytes = 0;
                hashData[flowOfDevice.name].detail[flowOfDevice.mac].down_bytes = 0;
                hashData[flowOfDevice.name].detail[flowOfDevice.mac].up_bps = 0;
                hashData[flowOfDevice.name].detail[flowOfDevice.mac].down_bps = 0;
                hashData[flowOfDevice.name].detail[flowOfDevice.mac].name = flowOfDevice.deviceDescription;
            }

            hashData[flowOfDevice.name].detail[flowOfDevice.mac].up_bytes += flowOfDevice.up_bytes;
            hashData[flowOfDevice.name].detail[flowOfDevice.mac].down_bytes += flowOfDevice.down_bytes;
            hashData[flowOfDevice.name].detail[flowOfDevice.mac].up_bps += flowOfDevice.up_bps;
            hashData[flowOfDevice.name].detail[flowOfDevice.mac].down_bps += flowOfDevice.down_bps;

        } // else if (showBy == "application") {
    } // for (var index in flowData)

    var returnData = [];
    for (var key in hashData) {
        returnData.push(hashData[key]);
    } // for (var index in flowData)

    function compare(a,b)
    {
        if(sortByData ? a.down_bytes + a.up_bytes > b.down_bytes + b.up_bytes : a.down_bps + a.up_bps > b.down_bps + b.up_bps)
            return -1;
        if(sortByData ? a.down_bytes + a.up_bytes < b.down_bytes + b.up_bytes : a.down_bps + a.up_bps < b.down_bps + b.up_bps)
            return 1;
        return 0;
    };

    returnData.sort(compare);

    return returnData;
}

function convertTimeUsageDataToSortable(srcData) {
    var targetData = [];

    for(var policyID in srcData) {
        targetData.push ( { policyID: policyID, sortValue: srcData[policyID].flowUpTimeNotOverlappedInMinutes, data:srcData[policyID]  } );
    }

    return targetData;

} // function convertTImeUsageDataToSortable(srcData) {

function sortTimeUsageData(srcData) {
    if (typeof srcData == "undefined" || srcData == null) {
        return null;
    }

    function compare(a,b)
    {
        if(a.sortValue > b.sortValue)
            return -1;
        if(a.sortValue < b.sortValue)
            return 1;
        return 0;
    };

    srcData.sort(compare);

    return srcData;

} // function sortTimeUsageData(srcData) {

function getTimeUsageDataByDateRange(srcData, range) {
    var targetData = {};

    for(var index in srcData) {

        var startTimestamp = srcData[index].startTimestamp;
        var endTimestamp = srcData[index].endTimestamp;

        // console.log("srcData[" + index + "]: ");
        // console.log(srcData[index]);
        // console.log("  start: " + stringOfFormattedTimestamp(startTimestamp));
        // console.log("  end: " + stringOfFormattedTimestamp(endTimestamp));

        if ( (startTimestamp >= range.startTimestamp && startTimestamp <= range.endTimestamp) &&
             (endTimestamp >= range.startTimestamp && endTimestamp <= range.endTimestamp) ) {
            for (var macAddr in srcData[index].devices) {
                for (var flowID in srcData[index].devices[macAddr].flows) {
                    // console.log('flowID:');
                    // console.log(flowID);
                    // console.log('srcData[index].devices[macAddr].flows[flowID]:');
                    // console.log(srcData[index].devices[macAddr].flows[flowID]);

                    if (typeof targetData[macAddr] == 'undefined') {
                        targetData[macAddr] = {};
                        targetData[macAddr].flows = {};
                    }

                    if (typeof targetData[macAddr].flows[flowID] == 'undefined') {
                        targetData[macAddr].flows[flowID] = {};

                        //global byte counts across all devices
                        targetData[macAddr].flows[flowID].rx_bytes = 0;
                        targetData[macAddr].flows[flowID].tx_bytes = 0;
                        targetData[macAddr].flows[flowID].uptime = 0;
                        targetData[macAddr].flows[flowID].flowUpTimeNotOverlappedInMinutes = 0;
                        targetData[macAddr].flows[flowID].rxHourly = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
                        targetData[macAddr].flows[flowID].txHourly = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
                    }

                    if (typeof srcData[index].devices[macAddr].flows[flowID] != 'undefined') {
                        targetData[macAddr].flows[flowID].rx_bytes += srcData[index].devices[macAddr].flows[flowID].rx_bytes;
                        targetData[macAddr].flows[flowID].tx_bytes += srcData[index].devices[macAddr].flows[flowID].tx_bytes;
                        targetData[macAddr].flows[flowID].uptime += srcData[index].devices[macAddr].flows[flowID].uptime;
                        if (typeof srcData[index].devices[macAddr].flows[flowID].flowUpTimeNotOverlappedInMinutes != "undefined" && srcData[index].devices[macAddr].flows[flowID].flowUpTimeNotOverlappedInMinutes != null) {
                            targetData[macAddr].flows[flowID].flowUpTimeNotOverlappedInMinutes += srcData[index].devices[macAddr].flows[flowID].flowUpTimeNotOverlappedInMinutes;
                        }
                        else {
                            // console.log("flowUpTimeNotOverlappedInMinutes is not defined!");
                        }
                    }

                }
            } // for (var macAddr in rawData[x].devices) {
        } // if ( (startTimestamp >= range.startTimestamp && startTimestamp <= range.endTimestamp) &&
        else {
            // console.log("  *** data was filtered time range!");
        }

    }

    return targetData;
} // function getTimeUsageDataByDateRange() {

function updateInstantFlowData(accumulatedInstantFlowData, currentInstantFlowData) {
    if (accumulatedInstantFlowData == null) {
        return currentInstantFlowData;
    }

    // update flowData

    var forceUpdateInSecond = 5;

    for (var index in currentInstantFlowData) {
        var uidInAccumIndex = uidIndexInFlowData(currentInstantFlowData[index].uid, accumulatedInstantFlowData);
        if (uidInAccumIndex != -1) {
            // console.log("update uid:" + currentInstantFlowData[index].uid);

            var diffEpochDownload = 0;

            if (typeof accumulatedInstantFlowData[uidInAccumIndex].down_bps_lastEpoch != "undefined") {
                diffEpochDownload = currentInstantFlowData[index].epoch - accumulatedInstantFlowData[uidInAccumIndex].down_bps_lastEpoch;
            }

            // calculate bps
            var down_bps = calculateBPS(accumulatedInstantFlowData[uidInAccumIndex].down_bytes,
                                        currentInstantFlowData[index].down_bytes,
                                        accumulatedInstantFlowData[uidInAccumIndex].epoch,
                                        currentInstantFlowData[index].epoch);

            if (down_bps > 0 || diffEpochDownload > forceUpdateInSecond) {
                accumulatedInstantFlowData[uidInAccumIndex].down_bps = down_bps;
                accumulatedInstantFlowData[uidInAccumIndex].down_bps_lastEpoch = currentInstantFlowData[index].epoch;
            }

            var diffEpochUpload = 0;

            if (typeof accumulatedInstantFlowData[uidInAccumIndex].up_bps_lastEpoch != "undefined") {
                diffEpochUpload = currentInstantFlowData[index].epoch - accumulatedInstantFlowData[uidInAccumIndex].up_bps_lastEpoch;
            }

            var up_bps = calculateBPS(accumulatedInstantFlowData[uidInAccumIndex].up_bytes,
                                        currentInstantFlowData[index].up_bytes,
                                        accumulatedInstantFlowData[uidInAccumIndex].epoch,
                                        currentInstantFlowData[index].epoch);

            if (up_bps > 0 || diffEpochUpload > forceUpdateInSecond) {
                accumulatedInstantFlowData[uidInAccumIndex].up_bps = up_bps;
                accumulatedInstantFlowData[uidInAccumIndex].up_bps_lastEpoch = currentInstantFlowData[index].epoch;
            }

            // override property
            accumulatedInstantFlowData[uidInAccumIndex].up_bytes   = currentInstantFlowData[index].up_bytes;
            accumulatedInstantFlowData[uidInAccumIndex].down_bytes = currentInstantFlowData[index].down_bytes;
            accumulatedInstantFlowData[uidInAccumIndex].epoch      = currentInstantFlowData[index].epoch;
        }
        else {
            console.log("insert uid:" + currentInstantFlowData[index].uid);
            accumulatedInstantFlowData.push(currentInstantFlowData[index]);
        }
    }

    return accumulatedInstantFlowData;

} // function updateInstantFlowData(accumulatedInstantFlowData, currentInstantFlowData) {

function zeroHourOfTimestamp(timestamp) {
    var timestamp = parseInt(timestamp);
    var date = new Date(0);
    date.setUTCSeconds(timestamp);
    date.setHours(0,0,0);
    return parseInt(date.getTime() / 1000);
}

function lastHourOfTimestamp(timestamp) {
    var timestamp = parseInt(timestamp);
    var date = new Date(0);
    date.setUTCSeconds(timestamp);
    date.setHours(23,59,59);
    return parseInt(date.getTime() / 1000);
}

function doPreCalculationIfNeeded(finishedCallback) {
    var oldestEventTimestamp = getOldestEventTimestamp();

    // console.log( 'oldestEventTimestamp:' + oldestEventTimestamp);

    var formattedOldestEventTimestamp = stringOfFormattedTimestamp(oldestEventTimestamp);
    console.log( 'formattedOldestEventTimestamp:' + formattedOldestEventTimestamp);

    var currentTimestamp = getCurrentTimestamp();

    // console.log( 'currentTimestamp:' + currentTimestamp + ', '+ stringOfFormattedTimestamp(currentTimestamp));

    var zeroHourOfOldestTimestamp = zeroHourOfTimestamp(oldestEventTimestamp);
    // console.log('zeroHourOfOldestTimestamp: ' + zeroHourOfOldestTimestamp + ', '+ stringOfFormattedTimestamp(zeroHourOfOldestTimestamp))

    var lastHourOfCurrentTimestamp = lastHourOfTimestamp(currentTimestamp);
    // console.log('lastHourOfCurrentTimestamp: ' + lastHourOfCurrentTimestamp + ', '+ stringOfFormattedTimestamp(lastHourOfCurrentTimestamp))

    var diffDays = diffDaysBetweenTimestamp(currentTimestamp, oldestEventTimestamp);
    // console.log( 'diffDays between oldest & current:' + diffDays);

    var diffDaysZero = diffDaysBetweenTimestamp(lastHourOfCurrentTimestamp, zeroHourOfOldestTimestamp);
    console.log( 'diffDays between zero oldest & current:' + diffDaysZero);

    diffDays = diffDaysZero;
    currentTimestamp = lastHourOfCurrentTimestamp;

    var walkOfDays = 0;

    if (diffDays > g_MaximumDaysToKeepFlowData) {
        diffDays = g_MaximumDaysToKeepFlowData;
    }

    console.log( 'diffDays between oldest & current:' + diffDays);


    // check if need to precalculate flow data
    if (oldestEventTimestamp > 0 &&
        g_nTotalEventFlows > 0 &&
        diffDays - g_nTotalPreCalculatedFlows > 1) {
        // removePrecalculatedAndNodeHistory();
        walkOfDays = diffDays;
    }
    else {
        walkOfDays = 1;
    }

    if (walkOfDays > g_MaximumDaysToKeepFlowData) {
        walkOfDays = g_MaximumDaysToKeepFlowData;
    }

    var originalDays = walkOfDays;

    function hideModal() {
        $("body").removeClass("loading");
        $("#divModal").hide();
        $("#divModalDescriptionDialog").dialog("close");
    }

    function precalculateDataCallback(data, retCode) {
        if (retCode > 0) {
            hideModal();
            finishedCallback();
            return;
        }

        // var previousTimeStamp = data.preCalculatedTimestamp;
        -- walkOfDays;
        var timestamp = currentTimestamp - walkOfDays * 86400;

        // console.log("walkOfDays: " + walkOfDays);

        if (walkOfDays < 1 || diffDaysBetweenTimestamp(timestamp, getCurrentTimestamp()) <= 0) {
            hideModal();
            finishedCallback();
            return;
        }
        if(originalDays != 1) {
            $("#divModalDescription").html("Updating Data (" + (originalDays - walkOfDays) + "/" + originalDays + "), please wait");
        }

        console.log( 'precalculateData of timestamp:' + stringOfFormattedTimestamp(timestamp));
        precalculateData(timestamp, precalculateDataCallback);
    }

    var timestamp = currentTimestamp - walkOfDays * 86400;
    $("body").addClass("loading");
    $("#divModalDescriptionDialog").dialog("open");
    if(originalDays == 1) {
        $("#divModalDescription").html("");
    }
    else {
        $("#divModalDescription").html("Updating Data (" + (originalDays - walkOfDays) + "/" + originalDays + "), please wait");
    }
    $("#divModal").show();
    console.log( 'precalculateData of timestamp:' + stringOfFormattedTimestamp(timestamp));
    precalculateData(timestamp, precalculateDataCallback);

}

function newEmptyCullData(startTimestamp, endTimestamp) {
    return {    startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                devices: {},
                flowPeak: {},
                macPeak: {},
                overallPeak: { peakOverall: 0,
                                peakOverallTimestamp: 0,
                                peakRx: 0,
                                peakRxTimestamp: 0,
                                peakTx: 0,
                                peakTxTimestamp: 0},
                rx_total: 0,
                tx_total: 0
            };
}

function newEmptyFlowData() {

    return {  policyID: "policydb:policies:default",
              sortValue: 0,
              data: {  rxHourly: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                       txHourly: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                       flowUpTimeNotOverlappedInMinutes: 0,
                       rx_bytes: 0,
                       tx_bytes: 0,
                       uptime: 0
                    }
            };
}

function timeRangeExistsInCullData(startTimestamp, endTimestamp, cullData) {

    if (typeof cullData == 'undefined' || cullData == null || cullData.length == 0) {
        return false;
    }

    var date = new Date();

    for (var index in cullData) {
        if ( zeroHourOfTimestamp(cullData[index].startTimestamp + date.getTimezoneOffset() * 60) == startTimestamp ) {
            return true;
        }
    }

    return false;
}

function appendEmptyData(cullData, nStartMS, nEndMS) {
    // console.log("appendEmptyData, nStartMS: " + stringOfFormattedTimestamp(nStartMS) + ", nEndMS: " + stringOfFormattedTimestamp(nEndMS));

    var zeroHourOfCurrentTimestamp = zeroHourOfTimestamp(getCurrentTimestamp());

    if (typeof cullData == 'undefined' || cullData == null || cullData.length == 0) {
        cullData = [];
        for (var walkTime = nStartMS; walkTime <= nEndMS; walkTime +=86400) {
            if (walkTime != zeroHourOfCurrentTimestamp) {
                cullData.push(newEmptyCullData(walkTime, walkTime + 86400));
                // console.log("appendEmptyData on time: " + stringOfFormattedTimestamp(walkTime));
            }
        }
        return true;
    }

    var hasAppendData = false;

    for (var walkTime = nStartMS; walkTime <= nEndMS; walkTime +=86400) {
        if (timeRangeExistsInCullData(walkTime, walkTime + 86400, cullData) == false) {
            if (walkTime != zeroHourOfCurrentTimestamp) {
                // console.log("appendEmptyData on time: " + stringOfFormattedTimestamp(walkTime));
                cullData.push(newEmptyCullData(walkTime, walkTime + 86400));
                hasAppendData = true;
            }
        }
    }

    return hasAppendData;

    // var date = new Date();
    // var dataStartTimestamp = cullData[0].startTimestamp + date.getTimezoneOffset() * 60;

    // // console.log("dataStartTimestamp: " + stringOfFormattedTimestamp(dataStartTimestamp));
    // if (typeof dataStartTimestamp == 'undefined' || dataStartTimestamp == null) {
    //     return false;
    // }

    // if (dataStartTimestamp > nStartMS && dataStartTimestamp - nStartMS > 86400) {
    //     var endTimestamp = dataStartTimestamp;
    //     for (var walkTime = nStartMS; endTimestamp > walkTime; walkTime +=86400) {
    //         // console.log("appendEmptyData on time: " + stringOfFormattedTimestamp(walkTime));
    //         // console.log("  walkTime: " + walkTime + ", endTimestamp: " + endTimestamp);
    //         cullData.push(newEmptyCullData(walkTime, walkTime + 86400));
    //     }
    //     return true;
    // }

    // for (var index in cullData) {
    //     console.log(stringOfFormattedTimestamp(cullData[index].startTimestamp));
    //     console.log(cullData[index]);
    // }
    // return false;
} // function appendEmptyData(cullData, nStartMS, nEndMS) {

function appendPreCalculatedPerFlowData(targetData, srcData){
    // console.log('targetData: ');
    // console.log(targetData);
    // console.log('srcData: ');
    // console.log(srcData);

    targetData = [];
    targetData.flows = {};
    targetData.rx_total = 0;
    targetData.tx_total = 0;

    for (var index in srcData) {
        // console.log('srcData[index]:');
        // console.log(srcData[index]);
        for (var mac in srcData[index].devices) {
            for (var flowID in srcData[index].devices[mac].flows) {
                // console.log('flowID:');
                // console.log(flowID);
                // console.log('srcData[index].devices[mac].flows[flowID]:');
                // console.log(srcData[index].devices[mac].flows[flowID]);

                if (typeof targetData.flows[flowID] == 'undefined') {
                    targetData.flows[flowID] = {};

                    //global byte counts across all devices
                    targetData.flows[flowID].rx_total = 0;
                    targetData.flows[flowID].tx_total = 0;
                    targetData.flows[flowID].uptime = 0;
                }

                if (typeof srcData[index].devices[mac].flows[flowID] != 'undefined') {
                    targetData.flows[flowID].rx_total += srcData[index].devices[mac].flows[flowID].rx_bytes;
                    targetData.flows[flowID].tx_total += srcData[index].devices[mac].flows[flowID].tx_bytes;
                    targetData.flows[flowID].uptime += srcData[index].devices[mac].flows[flowID].uptime;
                    targetData.rx_total += srcData[index].devices[mac].flows[flowID].rx_bytes;
                    targetData.tx_total += srcData[index].devices[mac].flows[flowID].tx_bytes;

                }

            }
        } // for (var mac in srcData[index].devices) {

    } // for (var data in srcData) {

    // console.log('after appendPreCalculatedPerFlowData, targetData: ');
    // console.log(targetData);
    return targetData;
} // appendPreCalculatedPerFlowData

function appendPreCalculatedPerDeviceData(targetData, srcData){
    // console.log('targetData: ');
    // console.log(targetData);
    // console.log('srcData: ');
    // console.log(srcData);

    // if (targetData == null) {
        targetData = []
    // }
    for (var index in srcData) {
        if (typeof targetData.devices == 'undefined' &&
            typeof srcData[index].devices != 'undefined') {
            // console.log('srcData[index].devices');
            //init the device array inside our return
            targetData.devices = {};

            //global byte counts across all devices
            targetData.rx_total = srcData[index].rx_total;
            targetData.tx_total = srcData[index].tx_total;
        }

        targetData.rx_total += srcData[index].rx_total;
        targetData.tx_total += srcData[index].tx_total;
        for (var mac in srcData[index].devices) {
            // console.log('append mac to targetData:');
            // console.log(mac);
            if(typeof targetData.devices[mac] == 'undefined') {
                // targetData.devices[mac] = srcData[index].devices[mac];
                targetData.devices[mac] = {};
                targetData.devices[mac].rx_total = 0;
                targetData.devices[mac].tx_total = 0;
            }

            targetData.devices[mac].rx_total += srcData[index].devices[mac].rx_total;
            targetData.devices[mac].tx_total += srcData[index].devices[mac].tx_total;

            // flow
            if(typeof targetData.devices[mac].flows == 'undefined') {
                // targetData.devices[mac].flows = srcData[index].devices[mac].flows;
                targetData.devices[mac].flows = {};
                targetData.devices[mac].flows.rx_total = 0;
                targetData.devices[mac].flows.tx_total = 0;
            }

            targetData.devices[mac].flows.rx_total += srcData[index].devices[mac].flows.rx_total;
            targetData.devices[mac].flows.tx_total += srcData[index].devices[mac].flows.tx_total;

            for (var flowID in srcData[index].devices[mac].flows) {
                if (typeof targetData.devices[mac].flows[flowID] == 'undefined') {
                    //init te flow
                    targetData.devices[mac].flows[flowID] = {};
                    targetData.devices[mac].flows[flowID].rx_bytes = 0;
                    targetData.devices[mac].flows[flowID].tx_bytes = 0;
                }
                targetData.devices[mac].flows[flowID].rx_bytes += srcData[index].devices[mac].flows[flowID].rx_bytes;
                targetData.devices[mac].flows[flowID].tx_bytes += srcData[index].devices[mac].flows[flowID].tx_bytes;
            }
        } // for (var mac in srcData[index].devices) {

    } // for (var data in srcData) {

    // console.log('after appendPreCalculatedPerDeviceData, targetData: ');
    // console.log(targetData);
    return targetData;
}

//do we have to draw ie style
function isMS()
{
    var bReturn = false;
    var ua = window.navigator.userAgent;
    var msie = ua.indexOf("MSIE ");

    if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./))
    {
        bReturn = true;
    }

    return bReturn;
}

/*
    color range used for pie charts
*/
var colorrange =    [   '#40699c',
                        '#9e413e',
                        '#7f9a48',
                        '#695185',
                        '#3c8da3',
                        '#cc7b38',
                        '#4f81bd',
                        '#c0504d',
                        '#9bbb59',
                        '#8064a2',
                        '#4bacc6',
                        '#f79646'
                    ];
/*
    Function: addPieKey

    add a key with icon/name for a pie element and draw a line
    to the pie wedge

    Parameters:
    strIcon     - path and icon to show on key
    strName     - name to display after icon on the key
    strMac      - mac of the node for click thru to details
    nItemX      - x postiton of key
    nItemY      - y positino of key
    strSlice    - pie wedge to draw line too
    chart       - chart class for drawing
    rgb         - rgb color of the key background puck
    handler     - Click callback handler
    bSelected   - Draw the item selected true/false

    returns:
    nothing
*/
function addPieKey( strIcon,
                    strName,
                    strMac,
                    nItemX,
                    nItemY,
                    slice,
                    chart,
                    rgb,
                    handler,
                    bSelected,
                    nHeight)
{

    //the chart query interface
    var cli = chart.getChartLayoutInterface();

    //get the bounding box of the target wedge
    var bbox = cli.getBoundingBox("slice#"+slice);

    // The ratio between nHeight & width ,
    // note nHeight * nRatioWidth must >= nMinWidth.
    var nRatioWidth = 3.56;

    var nMinWidth = 256;

    var nMaxFontSize = 14;

    //if the bounding box is real
    if(bbox != null)
    {
        //get center of bounding box
        var nPieX = Math.round(bbox.left + (bbox.width / 2));
        var nPieY = Math.round(bbox.top + (bbox.height / 2));

        // Handler for .ready() called.
        var graph = d3.select('svg');

        var defs = graph.append("defs");

        // create filter with id #drop-shadow
        // height=130% so that the shadow is not clipped
        var filter = defs.append("filter")
            .attr("id", "drop-shadow")
            .attr("height", "130%");

        // SourceAlpha refers to opacity of graphic that this filter will be applied to
        // convolve that with a Gaussian with standard deviation 3 and store result
        // in blur
        filter.append("feGaussianBlur")
            .attr("in", "SourceAlpha")
            .attr("stdDeviation", 5)
            .attr("result", "blur");

        // translate output of Gaussian blur to the right and downwards with 2px
        // store result in offsetBlur
        filter.append("feOffset")
            .attr("in", "blur")
            .attr("dx", 5)
            .attr("dy", 5)
            .attr("result", "offsetBlur");

        // overlay original SourceGraphic over translated blurred opacity by using
        // feMerge filter. Order of specifying inputs is important!
        var feMerge = filter.append("feMerge");

        feMerge.append("feMergeNode")
            .attr("in", "offsetBlur")
        feMerge.append("feMergeNode")
            .attr("in", "SourceGraphic");

        var nWidthOfRect = nHeight * nRatioWidth;

        if (nWidthOfRect < nMinWidth)
        {
            nWidthOfRect = nMinWidth;
        }

        var nFontSize = nHeight -2;

        if (nFontSize > nMaxFontSize)
        {
            nFontSize = nMaxFontSize;
        }

        var rect = graph.append("rect")
            .attr("rx", 16)
            .attr("ry", 16)
            .attr("x", nItemX)
            .attr("y", nItemY)
            .attr("width", nWidthOfRect)
            .attr("height", nHeight)
            .style("fill", rgb);

        if(isMS() == false)
        {
            rect.style("filter", "url(#drop-shadow)");
        }

        //make the image for the device/flow icon
        var img = graph.append("svg:image")
            .on("error", function() {
                d3.select(this).attr('xlink:href', "/images/default.png");
            })
            .attr('xlink:href', strIcon)
            .attr("x", nItemX + 8)
            .attr("y", nItemY + 4)
            .attr("width", nHeight - 8)
            .attr("height", nHeight - 8);

        var nStartX = nItemX + nWidthOfRect - 10;
        var nStartY = nItemY + nHeight / 2.0;

        var nEndX = nPieX;
        var nEndY = nPieY;

        var nMidX = nEndX; //nStartX+((nEndX-nStartX)/2);

        //draw the line to the pie wedgt
        var line1 = graph.append('line')
            .attr({
                'x1': nStartX,
                'y1': nStartY,
                'x2': nMidX,
                'y2': nStartY
            })
            .attr('class', 'unselect_line');

        //draw the end of the line
        var line2 = graph.append('line')
            .attr({
                'x1': nStartX,
                'y1': nStartY-1,
                'x2': nMidX,
                'y2': nStartY-1
            })
            .attr('class', 'unselect_line');

        //draw a line highlight/shadow
        var line3 = graph.append('line')
            .attr({
                'x1': nMidX,
                'y1': nStartY,
                'x2': nMidX,
                'y2': nEndY
            })
            .attr('class', 'unselect_line');

        //draw end line highlight/shadow
        var line4 = graph.append('line')
            .attr({
                'x1': nMidX-1,
                'y1': nStartY,
                'x2': nMidX-1,
                'y2': nEndY
            })
            .attr('class', 'unselect_line');

        //make a circle to star tthe line at
        var circle1 = graph.append("circle")
            .attr("cx", nStartX)
            .attr("cy", nStartY)
            .attr("r", 3)
            .style("fill", "black");

        //circle end point
        var circle2 = graph.append("circle")
            .attr("cx", nPieX)
            .attr("cy", nPieY)
            .attr("r", 3)
            .style("fill", "black");

        //make the label for the item flow/device
        var text = graph.append("text")
            .attr("x", nItemX + nHeight + 5)
            .attr("y", nItemY + nHeight / 1.5)
            .text(strName)
            .style("fill", "white")
            .style("font-size", nFontSize)
            .style("font-family", 'sans-serif');

        //is this item selected/selectable?
        if(bSelected == false)
        {
            //mouse hover handler
            var hMouseIn = function()
            {
                //is this item unselected?
                if(selected==null)
                {
                    //draw the selected state
                    options.slices={};
                    options.slices[parseInt(slice)] = {};
                    options.slices[parseInt(slice)].offset = .1;
                    drawChart(false,parseInt(slice));
                    $(this).css('cursor', 'pointer');
                    rect.style("fill", "#d8ad45");
                    text.style("fill", "black");
                    line1.attr('class', 'select_line');
                    line2.attr('class', 'select_line');
                    line3.attr('class', 'select_line');
                    line4.attr('class', 'select_line');
                    selected = slice;
                }
            }

            //mouse leave hover handler
            var hMouseOut = function()
            {
                //if we are currently selected
                if(selected!=null)
                {
                    //draw the unselected state
                    options.slices={};
                    //drawChart(false);
                    $(this).css('cursor', 'pointer');
                    rect.style("fill", rgb);
                    text.style("fill", "white");
                    line1.attr('class', 'unselect_line');
                    line2.attr('class', 'unselect_line');
                    line3.attr('class', 'unselect_line');
                    line4.attr('class', 'unselect_line');
                    selected = null;
                }
            }

            //hook up hover handlers on image
            img.on("mouseover",hMouseIn);
            img.on("mouseout",hMouseOut);

            //hook up hover handlers on puck rect
            rect.on("mouseover",hMouseIn);
            rect.on("mouseout",hMouseOut);

            //hook up hover handlers on the label
            text.on("mouseover",hMouseIn);
            text.on("mouseout",hMouseOut);

            //if we are selected and its not from a hover event
            if(typeof bSelected != 'undefined' && bSelected == true)
            {
                //draw the select state for the puck and text
                rect.style("fill", "#d8ad45");
                text.style("fill", "black");

                //select the line
                line1.attr('class', 'select_line');
                line2.attr('class', 'select_line');
                line3.attr('class', 'select_line');
                line4.attr('class', 'select_line');
            }
        }
        else //we are not selected
        {
            //make sure the pointer is the selection finger on hover
            $(this).css('cursor', 'pointer');

            //draw the unselected state for the puck and text
            rect.style("fill", "#d8ad45");
            text.style("fill", "black");

            //draw unselected lines
            line1.attr('class', 'select_line');
            line2.attr('class', 'select_line');
            line3.attr('class', 'select_line');
            line4.attr('class', 'select_line');
        }
        if(handler!='undefined')
        {
            //hook handler to icon
            img.on("click", handler);

            //hook handler to rounded rect
            rect.on("click", handler);

            //hook handler to text
            text.on("click", handler);
        }
    }
}

//curent selected item (geez a nasty global!)
var selected = null;

// Returns path data for a rectangle with rounded right corners.
// The top-left corner is ⟨x,y⟩.
/*function rightRoundedRect(x, y, width, height, radius)
{
    return "M" + x + "," + y + "h" + (width - radius) + "a" + radius + "," +
            radius + " 0 0 1 " + radius + "," + radius + "v" + (height - 2 * radius) +
            "a" + radius + "," + radius + " 0 0 1 " + -radius + "," + radius + "h" +
            (radius - width) + "z";
}*/

//Global dates for things
var g_dateCurrent  = new Date();

//get the currint date integers
var g_nCurrentYear  = g_dateCurrent.getFullYear();
var g_nCurrentMonth = g_dateCurrent.getMonth();
var g_nCurrentDay   = g_dateCurrent.getDate();

//calc end of month for default end date
var g_dateEnd = new Date(g_nCurrentYear,g_nCurrentMonth+1,0);

//calc four months back for default start
var g_nStartYear    = g_nCurrentYear;
var g_nStartMonth   = g_nCurrentMonth;

//if the start - 3 months is in the previous year
if(g_nCurrentMonth <= 2)
{
    g_nStartMonth = 12+(g_nCurrentMonth - 3);
    g_nStartYear = g_nCurrentYear - 1;
}
else
{
    g_nStartMonth -= 3;
}

var g_dateStart = new Date(g_nStartYear,g_nStartMonth,1);

function stringOfFormattedTimestamp(timestamp)
{
    var date = new Date(timestamp*1000);

    var nDay    = date.getDate();
    var nMonth  = date.getMonth()+1; //January is 0!
    var nYear   = date.getFullYear();
    var nHours = date.getHours();
    var nMinutes = "0" + date.getMinutes();
    var nSeconds = "0" + date.getSeconds();

    return  nYear + '/' + nMonth + '/' + nDay + ' ' + nHours + ':' +
            nMinutes.substr(-2) + ':' + nSeconds.substr(-2);

}

function getCurrentTimestamp()
{
    return Number(Date.now() /1000 |0);
}

function writeUsageInfo(resetDay, quotaUsage, warningThreshold, callback) {
    $.ajax({
        url: '/cgi-bin/ozkerz?writeDBUsageInfo=1&resetDay=' + resetDay + '&quotaUsage=' + quotaUsage + '&warningThreshold=' + warningThreshold,
        type: "GET",
        async: true,
        dataType: "json",
        cache: false,
        timeout: 30000,
        success: function(data, status, xhr) {
            callback(data, status);
        },
        error: function(data, status) {
            callback(data, status);
        }
    });
}

function getUsageInfo(callback) {
    $.ajax({
        url: '/cgi-bin/ozkerz?dbUsageInfo=1',
        type: "GET",
        async: true,
        dataType: "json",
        cache: false,
        timeout: 30000,
        success: function(data, status, xhr) {
            callback(data, status);
        },
        error: function(data, status) {
            callback(data, status);
        }
    });
}

function getLowBoundIndexByTimestamp(timestamp)
{
    var rtData = null;

    $.ajax({
        url: '/cgi-bin/ozkerz?lowBoundIndexByTimestamp=1&timestamp=' + timestamp,
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtData = data;
        },
        error: function(data, status) {
            rtData = 0;
        }
    });

    return rtData;
}

function removePrecalculatedAndNodeHistory()
{
    var rtData = null;

    $.ajax({
        url: '/cgi-bin/ozkerz?removePrecalculatedAndNodeHistory=1',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtData = data;
        },
        error: function(data, status) {
            rtData = status;
        }
    });

    return rtData;
}

function getNumbersOfFlowEvents()
{
    var rtData = null;

    $.ajax({
        url: '/cgi-bin/ozkerz?numOfCurrentEventFlows=1',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtData = data;
        },
        error: function(data, status) {
            rtData = status;
        }
    });

    return rtData;
}

function diffDaysBetweenTimestamp(tA, tB)
{
    var difference = Math.abs(tA - tB);
    // console.log(difference);
    var daysDifference = Math.ceil(difference/60/60/24);
    // console.log(daysDifference);
    return daysDifference;
}

function getOldestEventTimestamp()
{
    var rtData = null;

    $.ajax({
        url: '/cgi-bin/ozkerz?eventFlows=1&beginIndex=0&endIndex=0',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtData = data;
        },
        error: function(data, status) {
            rtData = status;
        }
    });

    if( typeof rtData.events != 'undefined' &&
        typeof rtData.events[0] != 'undefined' &&
        typeof rtData.events[0].time != 'undefined')
    {

        var timestamp = parseInt(rtData.events[0].time);
        var date = new Date(0);
        date.setUTCSeconds(timestamp);



        return parseInt(date.getTime() / 1000);

        // return parseInt(rtData.events[0].time);
    }

    return 0;

}

function precalculateDataOrShowOnly(timestamp, isShowingOnly, callback)
{
    $.ajax({
        // url: '/cgi-bin/ozker/api/events/flows',
        url: '/cgi-bin/ozkerz?preCalculateFlow' + (isShowingOnly ? "ShowOnly" : "") + '=1&timestamp=' + timestamp,
        type: "GET",
        async: true,
        dataType: "json",
        cache: false,
        timeout: 300000,
        success: function(data, status, xhr) {
            var retCode = 0;
            callback(data, retCode);
        },
        error: function(data, status) {
            // console.log( 'error getting /cgi-bin/ozker/api/events/flows' );
            $("#divDebugMesg").show().html("error ! statusCode: " + status+"<br/>"+$("#divDebugMesg").html());
            callback(data, status);
        }
    });
}

function precalculateData(timestamp, callback) {
    precalculateDataOrShowOnly(timestamp, false, callback);
}

function precalculateDataShowOnly(timestamp, callback) {
    precalculateDataOrShowOnly(timestamp, true, callback);
}

function retireOzker()
{
    var rtData = null;

    $.ajax({
        url: '/cgi-bin/ozkerz?retireOzker=1',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtData = 0;
        },
        error: function(data, status) {
            rtData = status;
        }
    });

    return rtData;
}

function lastDay(nYear, nMonth)
{
    var nexMonth = new Date(nYear, nMonth+1, 1);
    var dtLastDayOfMonth = new Date(nexMonth - 1);
    return dtLastDayOfMonth.getDate();
}

/*
    Function: getEvents

    get the long term events from the ozker api
    start and end are in utcsecond not date objects

    Parameters:
    start   - start time of the events you want
    end     - end time of the events you want

    returns:
    all the event between start and end
*/
function getEvents(start,end)
{
    var rtData = null;

    $.ajax({
        url: '/cgi-bin/ozker/api/events/flows',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {

            if(typeof start == 'undefined' || typeof end == 'undefined')
            {
                rtData = data.events;
            }
            else
            {
                rtData = [];

                var myTime = 0;

                if( typeof data.events != 'undefined' &&
                    typeof data.events[0] != 'undefined' &&
                    typeof data.events[0].time != 'undefined')
                {
                    myTime = parseInt(data.events[0].time);
                }

                g_dateStart = new Date(0);
                g_dateStart.setUTCSeconds(myTime);

                for(var x in data.events)
                {
                    var myTime = parseInt(data.events[x].time);

                    if(myTime >= start && myTime <= end)
                    {
                        rtData.push(data.events[x]);
                    }
                }

                g_dateEnd = new Date(0);
                g_dateEnd.setUTCSeconds(myTime);

            }
        },
        error: function(data, status) {
            rtData = status;
        }
    });

    return rtData;
}

/*
    cruddy global mutex for asyncEvents to stop stacking
*/
var g_bUpdating = false;

/*
    Function: asyncEvents

    get the long term events from the ozker api
    start and end are in utcsecond not date objects
    in an asynchronous mannet with a callback

    Parameters:
    start    - start time of the events you want
    end      - end time of the events you want
    callback - functino to call with data when done

    returns:
    nothing
*/
function asyncEvents(start, end, startIndex, endIndex, callback)
{
    var rtData = null;

    if (startIndex < 0)
    {
        startIndex = 0;
    }

    //is this routine already running?
    if(g_bUpdating == false)
    {
        //if not set it to running
        g_bUpdating = true;

        // console.log( 'start getting /cgi-bin/ozker/api/events/flows, ' + '/cgi-bin/ozkerz?eventFlows=1&beginIndex='+startIndex+'&endIndex='+endIndex);
        $.ajax({
            // url: '/cgi-bin/ozker/api/events/flows',
            url: '/cgi-bin/ozkerz?eventFlows=1&beginIndex='+startIndex+'&endIndex='+endIndex,
            type: "GET",
            async: true,
            dataType: "json",
            cache: false,
            timeout: 300000,
            success: function(data, status, xhr) {
                // console.log( 'success getting /cgi-bin/ozker/api/events/flows' );

                //clear the cruddy mutex
                g_bUpdating = false;

                var retCode = 0;

                //do we null range?
                if(typeof start == 'undefined' || typeof end == 'undefined')
                {
                    rtData = data.events;
                }
                else
                {
                    rtData = [];

                    if (data != null)
                    {
                        // Calculate  g_dateStart & g_dateEnd
                        var myTime = 0;

                        if( typeof data.events != 'undefined' &&
                            typeof data.events[0] != 'undefined' &&
                            typeof data.events[0].time != 'undefined')
                        {
                            myTime = parseInt(data.events[0].time);
                        }

                        g_dateStart = new Date(0);
                        g_dateStart.setUTCSeconds(myTime);

                        for(var x in data.events)
                        {
                            var myTime = parseInt(data.events[x].time);

                            // if(myTime >= start && myTime <= end)
                            {
                                rtData.push(data.events[x]);
                            }
                        }

                        g_dateEnd = new Date(0);
                        g_dateEnd.setUTCSeconds(myTime);

                    }
                    else
                    {
                        retCode = 'data is null';
                    }

                }

                callback(rtData, retCode);
            },
            error: function(data, status) {
                // console.log( 'error getting /cgi-bin/ozker/api/events/flows' );
                $("#divDebugMesg").show().html("error ! statusCode: " + status+"<br/>"+$("#divDebugMesg").html());
                rtData = status;
                callback(rtData, status);
            }
        });
    }
}


function asyncPerDevice(startIndex, endIndex, callback)
{
    var rtData = null;

    if (startIndex < 0)
    {
        startIndex = 0;
    }

    //is this routine already running?
    if(g_bUpdating == false)
    {
        //if not set it to running
        g_bUpdating = true;
        // console.log( 'start getting /cgi-bin/ozkerz?perDevice=1&beginIndex='+startIndex+'&endIndex='+endIndex);
        $.ajax({
            url: '/cgi-bin/ozkerz?perDevice=1&beginIndex='+startIndex+'&endIndex='+endIndex,
            type: "GET",
            async: true,
            dataType: "json",
            cache: false,
            timeout: 300000,
            success: function(data, status, xhr) {
                // console.log( 'success getting /cgi-bin/ozker/api/events/flows' );
                // console.log('data');
                // console.log(data);

                var currentPrecalculatedCallback = function(dataPrecalculatedToday, retCode) {
                    if (retCode == 0 && dataPrecalculatedToday != null && dataPrecalculatedToday.preCalculatedTimestamp != null) {
                        // console.log("dataPrecalculatedToday: ");
                        // console.log(dataPrecalculatedToday);
                        if (data != null && data.perDevice != null ) {
                            data.perDevice.unshift(dataPrecalculatedToday.preCalculatedTimestamp);
                        }
                    }

                    //clear the cruddy mutex
                    g_bUpdating = false;

                    var retCode = 0;

                    if (data != null)
                    {

                        rtData = data.perDevice;

                        // Calculate  g_dateStart & g_dateEnd
                        var myTime = 0;

                        if( typeof data.perDevice != 'undefined' &&
                            typeof data.perDevice[0] != 'undefined' &&
                            typeof data.perDevice[0].startTimestamp != 'undefined' &&
                            typeof data.perDevice[0].endTimestamp != 'undefined')
                        {
                            myTime = parseInt(data.perDevice[0].endTimestamp);

                            g_dateEnd = new Date(0);
                            g_dateEnd.setUTCSeconds(myTime);

                            var lastIndex = data.perDevice.length -1;

                            if( typeof data.perDevice[lastIndex] != 'undefined' &&
                                typeof data.perDevice[lastIndex].startTimestamp != 'undefined' &&
                                typeof data.perDevice[lastIndex].endTimestamp != 'undefined') {
                                myTime = parseInt(data.perDevice[lastIndex].startTimestamp);
                                g_dateStart = new Date(0);
                                g_dateStart.setUTCSeconds(myTime);
                            }

                        }



                    }
                    else
                    {
                        retCode = 'data is null';
                    }

                    callback(rtData, retCode);

                } // currentPrecalculatedCallback

                precalculateDataShowOnly(zeroHourOfTimestamp(getCurrentTimestamp()), currentPrecalculatedCallback);

            },
            error: function(data, status) {
                // console.log( 'error getting /cgi-bin/ozker/api/events/flows' );
                $("#divDebugMesg").show().html("error ! statusCode: " + status+"<br/>"+$("#divDebugMesg").html());
                rtData = status;
                callback(rtData, status);
            }
        });
    }
}

/*
    Function: getDeviceData

    take the event data and split by each device

    Parameters:
    rtData - raw data from getEvents()

    returns:
    api/events data broken down by device
*/
function getDeviceData(rtData, dataToPatch)
{
    //combine events in her for processing before return
    var eData = [];

    //walk the raw data
    for(var x in rtData)
    {
        var uuid = rtData[x].uuid;

        //does the event have a UUID?
        if(typeof eData[uuid] == 'undefined')
        {
            //if not create a blank one
            eData[uuid] = {};
        }

        //add part to regogize flow and device
        eData[uuid].uuid        = rtData[x].uuid;
        eData[uuid].flow_id     = rtData[x].flow_id;

        //was this an open event?
        if(rtData[x].event == "open")
        {
            //copy the open event it to or presort data
            eData[uuid].openTime    = rtData[x].time;
            eData[uuid].policy_id   = rtData[x].details.policy_id;
            eData[uuid].closeTime   = null;

            //set the device
            eData[uuid].mac          = rtData[x].mac;

            //open has no byte counts so init them to 0
            eData[uuid].rx_bytes = 0;
            eData[uuid].tx_bytes = 0;

            // console.log("eData["+uuid +"] :");
            // console.log(eData[uuid]);

        }
        else if(rtData[x].event == "milestone" || rtData[x].event == "close") //was this a close or milestone update?
        {
            //set the close time to the last update
            eData[uuid].closeTime = rtData[x].time;

            //update the byte counts
            eData[uuid].rx_bytes = parseIntFilterNaN(rtData[x].details.rx_bytes);
            eData[uuid].tx_bytes = parseIntFilterNaN(rtData[x].details.tx_bytes);
        }


    }

    // console.log('eData :');
    // console.log(eData);

    //create our return array
    var dData = [];

    //init the device array inside our return
    dData.devices = [];

    //global byte counts across all devices
    dData.rx_total = 0;
    dData.tx_total = 0;

    //pre calculate the totals
    for(var x in eData)
    {
        var mac = eData[x].mac;

        if(typeof mac == 'undefined')
        {
            var openFlow = findOpenFlowInDataToPatch(dataToPatch, x);
            if (openFlow != null)
            {
                eData[x].policy_id = openFlow.details.policy_id;
                eData[x].mac       = openFlow.mac;
                mac                = eData[x].mac ;
                // console.log('mac not found, lookup result: ' + mac);
            }
            else
            {
                // console.log('open flow is null, mac not found, original mac: ' + eData[x].mac);
                eData[x].policy_id = "uncategorized";
                eData[x].mac       = "Unknown device";
                mac                = eData[x].mac ;
            }

            // console.log('findOpenFlow result, UUID: ' + x + ', policy_id: ' + eData[x].policy_id + ', rx_bytes: ' + eData[x].rx_bytes + ', tx_bytes: ' + eData[x].tx_bytes + ', mac: ' + eData[x].mac );

        }

        //if this is a valid device
        if(typeof mac != 'undefined')
        {
            //get up down (for debuggin purposes)
            var nRx = eData[x].rx_bytes;
            var nTx = eData[x].tx_bytes;

            //do global byte counts
            dData.rx_total += nRx;
            dData.tx_total += nTx;
        }

    }

    //combine by device and flow
    for(var x in eData)
    {
        //get the device mac
        var mac = eData[x].mac;

        //if we have a valid device
        if(typeof mac != 'undefined')
        {
            //get up down (for debuggin purposes)
            var nRx = eData[x].rx_bytes;
            var nTx = eData[x].tx_bytes;

            //if this is the 1st time we've seen this device
            if(typeof dData.devices[mac] == 'undefined')
            {
                //create the device entry in our array
                dData.devices[mac] = {};
                dData.devices[mac].flows = {};
                dData.devices[mac].rx_total         = 0;
                dData.devices[mac].tx_total         = 0;
            }

            //get the flow
            var flow = eData[x].policy_id;

            //if this is the 1st time we've seen this flow
            if(typeof dData.devices[mac].flows[flow] == 'undefined')
            {
                //init te flow
                dData.devices[mac].flows[flow] = {};

                //init flow byte counts
                dData.devices[mac].flows[flow].rx_bytes   = 0;
                dData.devices[mac].flows[flow].tx_bytes   = 0;
                dData.devices[mac].flows[flow].uptime     = 0;
            }

            //do byte count
            dData.devices[mac].flows[flow].rx_bytes += nRx;
            dData.devices[mac].flows[flow].tx_bytes += nTx;

            //do device byte counts
            dData.devices[mac].rx_total += nRx;
            dData.devices[mac].tx_total += nTx;

            //do flow percent
            dData.devices[mac].flows[flow].rx_percent = ((dData.devices[mac].flows[flow].rx_bytes/dData.rx_total)*100).toFixed(2);
            dData.devices[mac].flows[flow].tx_percent = ((dData.devices[mac].flows[flow].tx_bytes/dData.tx_total)*100).toFixed(2);

            //do device  percent
            dData.devices[mac].rx_percent = ((dData.devices[mac].rx_total/dData.rx_total)*100).toFixed(2);
            dData.devices[mac].tx_percent = ((dData.devices[mac].tx_total/dData.tx_total)*100).toFixed(2);

            // uptime
            if(typeof eData[x].openTime  != 'undefined' &&
               typeof eData[x].closeTime  != 'undefined' &&
               eData[x].openTime != null &&
               eData[x].closeTime != null) {
                // console.log("openTime " + eData[x].openTime);
                // console.log("closeTime " + eData[x].closeTime);
                // console.log("uptime was " + dData.devices[mac].flows[flow].uptime);
                var uptime = eData[x].closeTime - eData[x].openTime;
                if (uptime > 0) {
                    dData.devices[mac].flows[flow].uptime += uptime;
                }
                // console.log("uptime is now " + dData.devices[mac].flows[flow].uptime);
            }

        }
    }

    // console.log('dData :');
    // console.log(dData);
    return dData;
}

/*
    Function: getMonthData

    get the by month flow data for the given device

    Parameters:
    rtData  - raw data from getevents()
    mac     - mac id of device to get data for

    returns:
    event data broken down by month
*/
function getMonthData(  rtData,
                        mac)
{
    //combine events
    var eData = [];


    var now = new Date().getTime();

    //walk the raw data and combine for futher processing
    for(var x in rtData)
    {
        var uuid = rtData[x].uuid;

        //if this is the 1st time we've seen this event
        if(typeof eData[uuid] == 'undefined')
        {
            eData[uuid] = {};
        }

        //create our event entry
        eData[uuid].uuid        = rtData[x].uuid;
        eData[uuid].flow_id     = rtData[x].flow_id;

        //if this is an open event
        if(rtData[x].event == "open")
        {
            eData[uuid].openTime = new Date(0); // The 0 there is the key, which sets the date to the epoch
            eData[uuid].openTime.setUTCSeconds(parseInt(rtData[x].time));

            eData[uuid].policy_id   = rtData[x].details.policy_id;
            eData[uuid].closeTime   = new Date(now); // The 0 there is the key, which sets the date to the epoch

            //set the device
            eData[uuid].mac         = rtData[x].mac;

            eData[uuid].rx_bytes = 0;
            eData[uuid].tx_bytes = 0;
        }
        else if(rtData[x].event == "milestone" || rtData[x].event == "close") // if this is a close or milestone update
        {
            eData[uuid].closeTime = new Date(0); // The 0 there is the key, which sets the date to the epoch
            eData[uuid].closeTime.setUTCSeconds(parseInt(rtData[x].time));

            eData[uuid].rx_bytes = parseIntFilterNaN(rtData[x].details.rx_bytes);
            eData[uuid].tx_bytes = parseIntFilterNaN(rtData[x].details.tx_bytes);
        }
    }

    //create return
    var months = [];

    //add an array for each month
    for(var m = 0; m<=12;m++)
    {
        months[m] = {};
        months[m].flows = [];
        months[m].rx_total   = 0;
        months[m].tx_total   = 0;
    }

    //walk the combined data and add to month buckets
    //filtered by the given mac
    for(var x in eData)
    {
        //if not our mac next!
        if(eData[x].mac != mac)
            continue;

        if(typeof eData[x].openTime == 'undefined')
        {
            eData[x].openTime = new Date(0);
        }

        //get the month of the event
        var month = eData[x].openTime.getMonth();

        //get the flow
        var flow = eData[x].policy_id;

        //get up down (for debuggin purposes)
        var nRx = eData[x].rx_bytes;
        var nTx = eData[x].tx_bytes;

        //if this is the 1st time we've seen this flow
        if(typeof months[month].flows[flow] == 'undefined')
        {
            months[month].flows[flow] = {};

            months[month].flows[flow].rx_bytes   = 0;
            months[month].flows[flow].tx_bytes   = 0;
        }

        //do byte count
        months[month].flows[flow].rx_bytes += nRx;
        months[month].flows[flow].tx_bytes += nTx;

        //do device byte counts
        months[month].rx_total += nRx;
        months[month].tx_total += nTx;

        //do flow percent
        months[month].flows[flow].rx_percent = ((months[month].flows[flow].rx_bytes/months[month].rx_total)*100).toFixed(2);
        months[month].flows[flow].tx_percent = ((months[month].flows[flow].tx_bytes/months[month].tx_total)*100).toFixed(2);
        // console.log("months[month].flows[flow]: ");
        // console.log(months[month].flows[flow]);
    }

    return months;
}

/*
    Function: getDayData

    get the by daily flow data for the given device

    Parameters:
    rtData  - raw data from getevents()
    mac     - mac id of device to get data for
    month   - month to break down by day

    returns:
    given month of flows broken down by daily activity
*/
function getDayData(  rtData,
                      mac,
                      nMonth)
{

    //combine events
    var eData = [];

    //get the current time
    var now = new Date().getTime();

    //walk the raw data and combine
    for(var x in rtData)
    {
        //event id
        var uuid = rtData[x].uuid;

        //if we haven't seen this event
        if(typeof eData[uuid] == 'undefined')
        {
            eData[uuid] = {};
        }

        //add event to our data
        eData[uuid].uuid        = rtData[x].uuid;
        eData[uuid].flow_id     = rtData[x].flow_id;

        //if this is an open event
        if(rtData[x].event == "open")
        {
            eData[uuid].openTime = new Date(0); // The 0 there is the key, which sets the date to the epoch
            eData[uuid].openTime.setUTCSeconds(parseInt(rtData[x].time));

            eData[uuid].policy_id   = rtData[x].details.policy_id;
            eData[uuid].closeTime   = new Date(now); // The 0 there is the key, which sets the date to the epoch

            //set the device
            eData[uuid].mac         = rtData[x].mac;
            //init byte counts
            eData[uuid].rx_bytes = 0;
            eData[uuid].tx_bytes = 0;
        }
        else if(rtData[x].event == "milestone" || rtData[x].event == "close") //if this is a close or milestone update event
        {
            eData[uuid].closeTime = new Date(0); // The 0 there is the key, which sets the date to the epoch
            eData[uuid].closeTime.setUTCSeconds(parseInt(rtData[x].time));

            //update byte counts
            eData[uuid].rx_bytes = parseIntFilterNaN(rtData[x].details.rx_bytes);
            eData[uuid].tx_bytes = parseIntFilterNaN(rtData[x].details.tx_bytes);
        }
    }

    //create return
    var days = [];
    var nMaxDay = 31;

    //add an array for each day
    for(var d = 0; d<=nMaxDay;d++)
    {
        days[d] = {};
        days[d].flows = [];
        days[d].rx_total   = 0;
        days[d].tx_total   = 0;
    }

    //walk the combined data and add to day buckets
    //filtered by the given mac
    for(var x in eData)
    {
        //if not our mac next!
        if(eData[x].mac != mac)
            continue;

        if(typeof eData[x].openTime == 'undefined')
        {
            // console.log('eData[x].openTime is undefined:');
            // console.log(eData[x]);
            eData[x].openTime = new Date(0);
        }

        var month   = eData[x].openTime.getMonth();
        var day     = eData[x].openTime.getDate();

        //if not our month
        if(month != nMonth)
            continue;

        var flow = eData[x].policy_id;

        //get up down (for debuggin purposes)
        var nRx = eData[x].rx_bytes;
        var nTx = eData[x].tx_bytes;

        //if this is the 1st time we've seen this flow
        if(typeof days[day].flows[flow] == 'undefined')
        {
            days[day].flows[flow] = {};

            days[day].flows[flow].rx_bytes   = 0;
            days[day].flows[flow].tx_bytes   = 0;
        }

        //do byte count
        days[day].flows[flow].rx_bytes += nRx;
        days[day].flows[flow].tx_bytes += nTx;

        //do device byte counts
        days[day].rx_total += nRx;
        days[day].tx_total += nTx;
    }

    return days;
}

function decumulateCheckPointTraffics(checkpoints)
{
    // console.log('before calculation, checkPoints: ');
    // console.log(checkpoints);

    var keys = Object.keys(checkpoints);
    for (var i = keys.length-1; i >= 1; --i)
    {
        var currentKey = keys[i];
        var previousKey = keys[i-1];
        checkpoints[currentKey].rx_bytes -= checkpoints[previousKey].rx_bytes;
        checkpoints[currentKey].tx_bytes -= checkpoints[previousKey].tx_bytes;
    }

    // console.log('after calculation, checkPoints: ');
    // console.log(checkpoints);

}

/*
    Function: getHourData

    get the by month flow data for the given device

    Parameters:
    rtData  - raw data from getevents()
    mac     - mac id of device to get data for
    nMonth  - month to use for data
    nDay    - day from nMonth to use for data

    returns:
    event data broke down by given month/day into hours of that day
*/
function getHourData( rtData,
                      mac,
                      nMonth,
                      nDay,
                      callback)
{

    // console.log("Start GetHourlyData of (month, day): (" + (nMonth + 1) + ", " + nDay + ")");
    var debugMesg = "";

    //combine events
    var eData = [];

    //get current time for unknown flow closes
    var now = new Date().getTime();

    //walk the raw data and combine
    for(var x in rtData)
    {
        //get the evnt id
        var uuid = rtData[x].uuid;

        //is this the 1st time we've seen the id?
        if(typeof eData[uuid] == 'undefined')
        {
            eData[uuid] = {};
        }

        //add our event info
        eData[uuid].uuid        = rtData[x].uuid;
        eData[uuid].flow_id     = rtData[x].flow_id;

        //is this an open event?
        if(rtData[x].event == "open")
        {
            eData[uuid].openTime = new Date(0); // The 0 there is the key, which sets the date to the epoch
            eData[uuid].openTime.setUTCSeconds(parseInt(rtData[x].time));

            eData[uuid].closeTime   = eData[uuid].openTime;

            eData[uuid].policy_id   = rtData[x].details.policy_id;

            //set the device
            eData[uuid].mac         = rtData[x].mac;

            //init byte counts
            eData[uuid].rx_bytes = 0;
            eData[uuid].tx_bytes = 0;
        }
        else if(rtData[x].event == "milestone" || rtData[x].event == "close") //is this a close / milestone update event?
        {

            if(typeof eData[uuid].checkPoints == 'undefined')
            {
                eData[uuid].checkPoints = {};
            }

            var utcTime = parseInt(rtData[x].time);
            eData[uuid].checkPoints[utcTime] = {};
            eData[uuid].checkPoints[utcTime].rx_bytes = parseIntFilterNaN(rtData[x].details.rx_bytes);
            eData[uuid].checkPoints[utcTime].tx_bytes = parseIntFilterNaN(rtData[x].details.tx_bytes);

            if (typeof eData[uuid].closeTime == 'undefined' ||
                utcTime > eData[uuid].closeTime.getUTCSeconds())
            {
                eData[uuid].closeTime = new Date(0); // The 0 there is the key, which sets the date to the epoch
                eData[uuid].closeTime.setUTCSeconds(utcTime);

                //update the ul/dl byte counts
                eData[uuid].rx_bytes = parseIntFilterNaN(rtData[x].details.rx_bytes);
                eData[uuid].tx_bytes = parseIntFilterNaN(rtData[x].details.tx_bytes);

            }

        }
    }

    //create return
    var hours = [];
    var nMaxHours = 23;

    //add an array for each houre
    for(var d = 0; d<=23;d++)
    {
        hours[d] = {};
        hours[d].flows = [];
        hours[d].rx_total   = 0;
        hours[d].tx_total   = 0;
    }

    //walk the combined data and add to day buckets
    //filtered by the given mac
    for(var x in eData)
    {
        //if not our mac next!
        if(eData[x].mac != mac)
            continue;

        // console.log('eData[x]:');
        // console.log(eData[x]);
        if(typeof eData[x].openTime == 'undefined')
        {
            // console.log('eData[x] has no openTime, set to date(0):');
            // console.log(eData[x]);
            eData[x].openTime = new Date(0);
        }

        if(typeof eData[x].closeTime == 'undefined')
        {
            // console.log('eData[x] has no closeTime, set to now:');
            // console.log(eData[x]);

            eData[x].closeTime   = new Date(now);
        }

        //get the exact month/day/hour of the event
        var startMonth   = eData[x].openTime.getMonth();
        var startDay     = eData[x].openTime.getDate();
        var startHour    = eData[x].openTime.getHours();

        var endMonth     = eData[x].closeTime.getMonth();
        var endDay       = eData[x].closeTime.getDate();
        var endHour      = eData[x].closeTime.getHours();

        // check month range
        if ( (startMonth <= nMonth && nMonth <= endMonth) == false )
        {
            continue;
        }

        // check day range
        if ( (startDay <= nDay && nDay <= endDay) == false )
        {
            continue;
        }

        // console.log('eData[x] in range, keep working:');
        // console.log(eData[x]);

        // data is within same hour
        if (startMonth == endMonth && startDay == endDay && startHour == endHour)
        {
            //get the flow id
            var flow = eData[x].policy_id;

            //get up down (for debuggin purposes)
            var nRx = eData[x].rx_bytes;
            var nTx = eData[x].tx_bytes;

            var hour = startHour;

            //is this the 1st time we've seen this flow in this hour?
            if(typeof hours[hour].flows[flow] == 'undefined')
            {
                //init the flow in this hour
                hours[hour].flows[flow] = {};
                hours[hour].flows[flow].rx_bytes   = 0;
                hours[hour].flows[flow].tx_bytes   = 0;
            }

            //do byte count
            hours[hour].flows[flow].rx_bytes += nRx;
            hours[hour].flows[flow].tx_bytes += nTx;

            //do device byte counts
            hours[hour].rx_total += nRx;
            hours[hour].tx_total += nTx;

            debugMesg += "hour: " + hour + ", result, UUID: " + x + ", policy_id: <font class=\"policy\">" + eData[x].policy_id + "</font>, rx_bytes: " + eData[x].rx_bytes + ", tx_bytes: " + eData[x].tx_bytes + ", mac: " + eData[x].mac + "<br/>&nbsp;&nbsp;openTime: <font class=\"openTime\">" + eData[x].openTime + "</font><br/>&nbsp;&nbsp;closeTime: <font class=\"closeTime\">" + eData[x].closeTime + "</font><br/>";
            // console.log('within same hour, hour: ' + hour + ', result, UUID: ' + x + ', policy_id: ' + eData[x].policy_id + ', rx_bytes: ' + eData[x].rx_bytes + ', tx_bytes: ' + eData[x].tx_bytes + ', mac: ' + eData[x].mac + ', openTime: ' + eData[x].openTime + ', closeTime: ' + eData[x].closeTime );
        } // data is within same hour
        else // data has crossed hours even days
        {
            // Walk through checkpoints to retrieve hourly data
            // console.log('eData[x] not within same hour, keep working:');
            // console.log(eData[x]);
            decumulateCheckPointTraffics(eData[x].checkPoints);
            for(var timestamp in eData[x].checkPoints)
            {
                var dateOfTimeStamp = new Date(0); // The 0 there is the key, which sets the date to the epoch
                dateOfTimeStamp.setUTCSeconds(timestamp);

                var tMonth     = dateOfTimeStamp.getMonth();
                var tDay       = dateOfTimeStamp.getDate();
                var tHour      = dateOfTimeStamp.getHours();

                // check month & day range
                if (tMonth != nMonth || tDay != nDay )
                {
                    continue;
                }

                //get the flow id
                var flow = eData[x].policy_id;

                //get up down (for debuggin purposes)
                var nRx = eData[x].checkPoints[timestamp].rx_bytes;
                var nTx = eData[x].checkPoints[timestamp].tx_bytes;

                var hour = tHour;

                // console.log('add to hour: '+ hour + ' with following data:');
                // console.log(eData[x].checkPoints[timestamp]);

                //is this the 1st time we've seen this flow in this hour?
                if(typeof hours[hour].flows[flow] == 'undefined')
                {
                    //init the flow in this hour
                    hours[hour].flows[flow] = {};
                    hours[hour].flows[flow].rx_bytes   = 0;
                    hours[hour].flows[flow].tx_bytes   = 0;
                }

                //do byte count
                hours[hour].flows[flow].rx_bytes += nRx;
                hours[hour].flows[flow].tx_bytes += nTx;

                //do device byte counts
                hours[hour].rx_total += nRx;
                hours[hour].tx_total += nTx;
            }

            debugMesg += "<font class=\"important\">*****</font>hour: " + hour + ", result, UUID: " + x + ", policy_id: <font class=\"policy\">" + eData[x].policy_id + "</font>, rx_bytes: " + eData[x].rx_bytes + ", tx_bytes: " + eData[x].tx_bytes + ", mac: " + eData[x].mac + "<br/>&nbsp;&nbsp;openTime: <font class=\"openTime\">" + eData[x].openTime + "</font><br/>&nbsp;&nbsp;closeTime: <font class=\"closeTime\">" + eData[x].closeTime + "</font><br/>";

        } // data has crossed hours even days

    }

    // console.log( 'hours:' );
    // console.log( hours );
    callback(debugMesg);

    // console.log("finish GetHourlyData of (month, day): (" + (nMonth + 1) + ", " + nDay + ")");

    return hours;
}

function getFlows(callback)
{
    $.ajax({
        url: '/cgi-bin/ozker/api/flows',
        type: "GET",
        async: true,
        dataType: "json",
        cache: false,
        timeout: 300000,
        success: function(data, status, xhr) {
            callback(data, 0);
        },
        error: function(data, status) {
            $("#divDebugMesg").show().html("error ! statusCode: " + status+"<br/>"+$("#divDebugMesg").html());
            callback(data, status);
        }
    });
}

/*
    Function: getDevices

    get all the devices this router has seen

    Parameters:
    none

    returns:
    return raw json from /api/ozker/nodes
*/
function getDevices()
{
    var rtDevices = {};

    $.ajax({
        url: '/cgi-bin/ozker/api/nodes',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtDevices = data.nodes;
        },
        error: function(data, status) {
            rtDevices = status;
        }
    });

    return rtDevices;
}

//nasty global storage for devices so we dont have to keep refetching this every update
var rtDevices = {};
//nasty global storage for policies so we dont have to keep refetching this every update
var rtPolicy = {};

/*
    Function: getPolicy

    get all the policies this router knows about

    none

    returns:
    return raw json from /api/ozker/policies
*/
function getPolicy()
{
    var dPolicy = {};

    $.ajax({
        url: '/cgi-bin/ozker/api/policies',
        type: "GET",
        async: false,
        dataType: "json",
        cache: false,
        timeout: 3000,
        success: function(data, status, xhr) {
            rtPolicy = dPolicy = data;
        },
        error: function(data, status) {
            dPolicy = status;
        }
    });

    return dPolicy;
}

/*
    Function: flowname

    take a flow id and get is readable name

    none

    returns:
    human readable flow name for the flow_id as given in
    events or /api/flows
*/
function flowname(strFlowID)
{
    //call the flowName in utility.js and get the readable name
    return flowName(policyname(strFlowID));
}


/*
    Function: policyname

    get the policy id for a given flow id

    ie:

    flowname = policydb:policies:counterstrikego
    policyid = counterstrikego

    none

    returns:
    a policy name for the flowid
*/
function policyname(strFlowID)
{
    //set the string given to return by default
    var strReturn = strFlowID;

    //if we have a table at all
    if(rtPolicy!=undefined && rtPolicy != null)
    {
        //to get the language string
        var strTemp = rtPolicy[strFlowID];

        //if we got back a valid string
        if(strTemp != undefined)
        {
            //set the return
            strReturn = strTemp.emit;
        }
    }

    //call the flowName in utility.js and get the readable name
    return strReturn;
}

/*
    Function: mac2name

    look up the given mac in /api/flow and find the
    human readable name

    Parameters:
    mac - mac address to look up

    returns:
    return the name for the given mac
*/
function mac2name(mac)
{
    //default to sending the mac back
    var name = mac;

    //walk the global rtDevices array
    for(var x in rtDevices)
    {
        //if we find the mac
        if(rtDevices[x].Pipeline.mac_addr == mac)
        {
            //if the device has a name
            if(rtDevices[x].Pipeline.name != undefined)
            {
                name = rtDevices[x].Pipeline.name.substring(0,13);
            }
            else if(rtDevices[x].Pipeline.type != undefined) // if the device has a device type
            {
                name = rtDevices[x].Pipeline.type;
            }
            else if(rtDevices[x].Pipeline.ip_addr != undefined) // if the device has an ip address
            {
                name = rtDevices[x].Pipeline.ip_addr;
            }

            break;
        }
    }

    return name;
}

/*
    Function: mac2type

    look up the given mac in /api/flow and find the
    human readable type of the device

    Parameters:
    mac - mac address to look up

    returns:
    return the device type for the given mac
*/
function mac2type(mac)
{
    //default to sending back nothing
    var type = "Unknown";

    //walk the global device list
    for(var x in rtDevices)
    {
        //if this is our mac
        if(rtDevices[x].Pipeline.mac_addr == mac)
        {
            //if this mac has a type
            if(rtDevices[x].Pipeline.type != undefined)
            {
                type = rtDevices[x].Pipeline.type;
            }
            break;
        }
    }

    return type;
}

/*
    Function: mac2ip

    look up the given mac in /api/flow and find the
    ip of the device

    Parameters:
    mac - mac address to look up

    returns:
    return the ip string for the given mac
*/
function mac2ip(mac)
{
    //return null if no ip found
    var ip = null;

    //wark the global device list
    for(var x in rtDevices)
    {
        //if this is our mac
        if(rtDevices[x].Pipeline.mac_addr == mac)
        {
            //get the mac if any
            if(rtDevices[x].Pipeline.ip_addr != undefined)
            {
                ip = rtDevices[x].Pipeline.ip_addr;
            }

            break;
        }
    }

    return ip;
}


/*
    Function: nodeIcon

    look up the give node id and find its icon and path

    Parameters:
    strNodeID - node id to look up

    returns:
    return the icon and path for the icon
*/
function nodeIcon(strNodeID)
{
    //set the string given to return by default
    var strReturn = "/images/UnknownDevice.png";

    //if we have a table at all
    if(g_strIcons!=undefined && g_strIcons != null)
    {
        //to get the icon
        // console.log(g_strIcons);
        var strTemp = g_strIcons[strNodeID];

        //if we got back a valid string
        if(strTemp != undefined)
        {
            //set the return
            strReturn = strTemp;
        }
    }

    return strReturn;
}

//global table of devices
var devicetable = [];

function findOpenFlowInDataToPatch(dataToPatch, uuid)
{

    var defaultFlow = null;

    if (dataToPatch == null)
    {
        return defaultFlow;
    }

    for(var x in dataToPatch)
    {
        if(dataToPatch[x].uuid == uuid && dataToPatch[x].event == "open") {
            return dataToPatch[x];
        }
    }

    return defaultFlow;

}

function findOpenFlow(uuid)
{
    var defaultFlow = null;

    if (rawData == null)
    {
        return defaultFlow;
    }

    for(var x in rawData)
    {
        if(rawData[x].uuid == uuid && rawData[x].event == "open")
        {
            return rawData[x];
        }
    }

    return defaultFlow;

}

function parseIntFilterNaN(obj)
{
    var val = parseInt(obj);
    return isNaN(val) ? 0 : val;
}

/*
    Function: getFlowData

    get the data split by each flow and device info removed

    Parameters:
    rtData - raw event data from getEvents()

    returns:
    api/events data broken down by flow
*/
function getFlowData(rtData)
{
    //combine events
    var eData = [];

    //walk the raw data
    for(var x in rtData)
    {
        //get the event id
        var uuid = rtData[x].uuid;

        //if this is the 1st time we have seen this event
        if(typeof eData[uuid] == 'undefined')
        {
            eData[uuid] = {};
        }

        //add event to our collection
        eData[uuid].uuid        = rtData[x].uuid;
        eData[uuid].flow_id     = rtData[x].flow_id;

        //if this is an open event
        if(rtData[x].event == "open")
        {
            //init our open data
            eData[uuid].openTime    = rtData[x].time;
            eData[uuid].policy_id   = rtData[x].details.policy_id;
            eData[uuid].closeTime   = null;

            eData[uuid].mac         = rtData[x].mac;

            //setup our bytes
            eData[uuid].rx_bytes = 0;
            eData[uuid].tx_bytes = 0;
        }
        else if(rtData[x].event == "milestone" || rtData[x].event == "close") //if this is a close or milestone update
        {
            //set the time
            eData[uuid].closeTime = rtData[x].time;

            //update the ul/dl byte counts
            eData[uuid].rx_bytes = parseIntFilterNaN(rtData[x].details.rx_bytes);
            eData[uuid].tx_bytes = parseIntFilterNaN(rtData[x].details.tx_bytes);
        }
    }

    console.log('eData:');
    console.log(eData);

    //create our return objecw
    var fData = {};

    //init the flow array in our return
    fData.flows = [];

    //init total byte counts
    fData.rx_total = 0;
    fData.tx_total = 0;

    //pre calculate the totals
    for(var x in eData)
    {
        //get the flow id
        var policy_id = eData[x].policy_id;

        if(typeof policy_id == 'undefined')
        {
            var openFlow = findOpenFlow(x);
            if (openFlow != null)
            {
                eData[x].policy_id = openFlow.details.policy_id;
                eData[x].mac       = openFlow.mac;
                policy_id          = eData[x].policy_id;
                // console.log('policy_id not found, lookup result: ' + policy_id);
            }
            else
            {
                eData[x].policy_id = "uncategorized";
                eData[x].mac       = "Unknown device";
                policy_id          = eData[x].policy_id;
            }

            // console.log('findOpenFlow result, UUID: ' + x + ', policy_id: ' + eData[x].policy_id + ', rx_bytes: ' + eData[x].rx_bytes + ', tx_bytes: ' + eData[x].tx_bytes + ', mac: ' + eData[x].mac );

        }

        //if this is the 1st time we've seen this id
        if(typeof policy_id != 'undefined')
        {
            //get up down (for debuggin purposes)
            var nRx = eData[x].rx_bytes;
            var nTx = eData[x].tx_bytes;

            //do global byte counts
            fData.rx_total += nRx;
            fData.tx_total += nTx;
        }
        else
        {
            console.log('policy_id[x] not found, x:');
            console.log(x);
        }

    }

    //combine by flow
    for(var x in eData)
    {
        //get the flow id
        var policy_id = eData[x].policy_id;

        //if this is a valid id
        if(typeof policy_id != 'undefined')
        {
            //get up down (for debuggin purposes)
            var nRx = eData[x].rx_bytes;
            var nTx = eData[x].tx_bytes;

            //if this is the 1st time we've seen this flow
            if(typeof fData.flows[policy_id] == 'undefined')
            {
                //init our new flow
                fData.flows[policy_id] = {};
                fData.flows[policy_id].flows = {};
                fData.flows[policy_id].rx_total         = 0;
                fData.flows[policy_id].tx_total         = 0;
            }

            //do flow byte counts
            fData.flows[policy_id].rx_total += nRx;
            fData.flows[policy_id].tx_total += nTx;


            //do flow percent
            fData.flows[policy_id].rx_percent = ((fData.flows[policy_id].rx_total/fData.rx_total)*100).toFixed(2);
            fData.flows[policy_id].tx_percent = ((fData.flows[policy_id].tx_total/fData.tx_total)*100).toFixed(2);
        }
        else
        {
            console.log('policy_id[x] not found, x:');
            console.log(x);
        }
    }

    return fData;
}


/*
    Function: flowTable

    get the flow table from the cloud for icons

    Parameters:
    callback - when we have grabbed the table this callback is called to signal done!

    returns:
    nothing but callback gets data for table on complete
*/
function flowTable(callback)
{
    //1st get the local language
    var strFile = "flows_"+getLanguage()+".js";

    //create the url by looking at the global path for this model of router
    var strURL = g_path.strings + strFile;

    var flowCallback = "jsonpFlowsCallback";

    if (typeof g_flowCallback != "undefined" && g_flowCallback != null) {
        flowCallback = g_flowCallback;
    }

    //load the table
    $.ajax({
                url: strURL,
                dataType: "jsonp",
                jsonpCallback: flowCallback,
                cache: false,
                timeout: 3000,
                success: function(data, status, request)
                {
                    //set the global language to the returned data
                    g_FlowTable = data;

                    //if the user gave us a callback tell
                    //them we are done
                    if(callback != undefined)
                    {
                        callback();
                    }
                },
                error: function(data,status)
                {
                    //we timed out, but still need to call the user
                    if(callback != undefined)
                    {
                        callback();
                    }
                }
    });
}

function monthRange(dtDate, nMonthOffset)
{
    var dtWorking = new Date(dtDate.getTime());
    // console.log(dtWorking);
    dtWorking.setMonth(dtWorking.getMonth() + nMonthOffset);
    // console.log(dtWorking);

    var nCurrentMonth = dtWorking.getMonth()+1;
    var nCurrentYear = dtWorking.getFullYear();

    var range = {nQuarter: 0, strStart: "1-1-15", strEnd: "1-31-15"};

    range.nQuarter = nMonthOffset;

    range.strStart = nCurrentMonth + "/1/" + nCurrentYear;
    range.strEnd   = nCurrentMonth + "/" + lastDay(nCurrentYear, nCurrentMonth -1) + "/" + nCurrentYear;

    return range;
}

function lastQuarterRange(dtDate, nMonthOffset)
{
    var dtWorking = new Date(dtDate.getTime());
    // console.log(dtWorking);
    dtWorking.setMonth(dtWorking.getMonth() + nMonthOffset);
    // console.log(dtWorking);

    var nWorkingMonth = dtWorking.getMonth()+1;
    var nWorkingYear = dtWorking.getFullYear();

    var range = {nQuarter: 0, strStart: "1-1-15", strEnd: "1-31-15"};

    range.nQuarter = nMonthOffset;

    range.strStart = nWorkingMonth + "/1/" + nWorkingYear;
    range.strEnd   = (dtDate.getMonth() + 1) + "/" + dtDate.getDate() + "/" + dtDate.getFullYear();

    return range;
}

function currentWeekRangeByTimestamp() {
    var curr = new Date; // get current date
    var first = curr.getDate() - curr.getDay(); // First day is the day of the month - the day of the week
    // var last = first + 6; // last day is the first day + 6

    var firstday = new Date(curr.setDate(first));
    firstday.setHours(0,0,0);

    var range = {startTimestamp: 0, endTimestamp: 0};

    var endDate = new Date();
    endDate.setHours(23,59,59);

    range.startTimestamp = firstday.getTime();
    range.endTimestamp   = endDate.getTime();

    return range;

    // var lastday = new Date(curr.setDate(last)).toUTCString();
}

function currentMonthRangeByTimestamp() {
    var dtWorking = new Date();

    var startDate = new Date(dtWorking.getFullYear(), dtWorking.getMonth(), 1);
    startDate.setHours(0,0,0);

    var range = {startTimestamp: 0, endTimestamp: 0};

    var endDate = new Date();
    endDate.setHours(23,59,59);

    range.startTimestamp = startDate.getTime();
    range.endTimestamp   = endDate.getTime();

    return range;
}

function currentQuarterRangeByTimestamp()
{
    var dtWorking = new Date();

    var nWorkingMonth = dtWorking.getMonth()+1;
    var nWorkingYear = dtWorking.getFullYear();

    var range = {nQuarter: 0, startTimestamp: 0, endTimestamp: 0};

    range.nQuarter = getQuarter(nWorkingMonth);

    if(range.nQuarter == 1)
    {
        nWorkingMonth = 1;
    }
    else if(range.nQuarter == 2)
    {
        nWorkingMonth = 4;
    }
    else if(range.nQuarter == 3)
    {
        nWorkingMonth = 7;
    }
    else // we are 4
    {
        nWorkingMonth = 10;
    }

    var startDate = new Date(nWorkingYear, nWorkingMonth - 1, 1);
    startDate.setHours(0,0,0);

    var endDate = new Date();
    endDate.setHours(23,59,59);

    range.startTimestamp = startDate.getTime();
    range.endTimestamp   = endDate.getTime();

    return range;
}

function pastRangeOfDaysByTimestamp(days) {
    var curr = new Date(); // get current date

    var first = curr.getDate() + days;

    var firstday = new Date(curr.setDate(first));
    firstday.setHours(0,0,0);

    var range = {startTimestamp: 0, endTimestamp: 0};

    var endDate = new Date();
    endDate.setHours(23,59,59);

    range.startTimestamp = firstday.getTime();
    range.endTimestamp   = endDate.getTime();

    return range;

    // var lastday = new Date(curr.setDate(last)).toUTCString();
}

function pastWeekRangeByTimestamp() {
    return pastRangeOfDaysByTimestamp(-6);
}

function pastMonthRangeByTimestamp() {
    return pastRangeOfDaysByTimestamp(-29);
}

function pastQuarterRangeByTimestamp() {
    return pastRangeOfDaysByTimestamp(-89);
}

//get what quarter the month is in
function getQuarter(nMonth)
{
    //set up arrays with quarter ranges
    var nQuarter = 0;

    //set the current quarter
    if(nMonth >=1 && nMonth <= 3)
    {
        nQuarter = 1;
    }
    else if(nMonth >=4 && nMonth <= 6)
    {
        nQuarter = 2;
    }
    else if(nMonth >=7 && nMonth <= 9)
    {
        nQuarter = 3;
    }
    else
    {
        nQuarter = 4;
    }

    return nQuarter;
}

//get the range of dates for the quarters of the given year
function quarterRange(nQuarter, nYear)
{
    var range = {nQuarter: 1, strStart: "1-1-15", strEnd: "3-31-15"};

    range.nQuarter = nQuarter;
    //set the current quarter
    if(nQuarter == 1)
    {
        range.strStart = "1/1/"+nYear;
        range.strEnd = "3/31/"+nYear;
    }
    else if(nQuarter == 2)
    {
        range.strStart = "4/1/"+nYear;
        range.strEnd = "6/30/"+nYear;
    }
    else if(nQuarter == 3)
    {
        range.strStart = "7/1/"+nYear;
        range.strEnd = "9/30/"+nYear;
    }
    else // we are 4
    {
        range.strStart = "10/1/"+nYear;
        range.strEnd = "12/31/"+nYear;
    }

    return range;
}


function strOfTimeDiffInMMSS(timeDiff)
{
    var totalSeconds = timeDiff;
    var minutes = Math.floor(totalSeconds / 1000 / 60);
    totalSeconds -= minutes * 1000 * 60;
    var seconds = Math.floor(totalSeconds / 1000);

    return minutes + " min " + seconds + " sec";
}

function refreshModalDescription(clearDescription, showDetailedMesg)
{
    var description = "";

    if (clearDescription)
    {
        description = "";
    }
    else if (g_nTotalEventFlows == g_nRemainingEventFlows)
    {
        description = "0%"
    }
    else
    {
        var percentage = (g_nTotalEventFlows - g_nRemainingEventFlows) / g_nTotalEventFlows;

        var dtNow = new Date();
        var timeDiff = dtNow - g_dStartFetchEventFlows;
        var timeEstimated = timeDiff / percentage * (1- percentage);

        description = (Math.round(percentage *100)) +"%";
        if (timeEstimated > g_nExtimatedExceed * 60 * 1000)
        {
            description += g_sFormatEstimatedExceed.format(g_nExtimatedExceed);
        }
        else
        {
            description += g_sFormatEstimatedNormal.format(strOfTimeDiffInMMSS(timeEstimated));
        }

        if (showDetailedMesg)
        {
            var per1000FlowTime = Math.round(timeDiff / (g_nTotalEventFlows - g_nRemainingEventFlows) *100) / 100;
            description += "<br/>Average event transfer time: " + per1000FlowTime + " seconds per 1000 events, " + Math.round(per1000FlowTime * 20000) / 100 + " seconds per 200,000 events.";
            description += "<br/>Number of events: " + (g_nTotalEventFlows - g_nRemainingEventFlows) + " / " + g_nTotalEventFlows + ", "  + strOfTimeDiffInMMSS(timeDiff) + " elapsed.";
        }
    }

    $("#divModalDescription").html(description);

}

function makeLoadingModalDialog(id, buttonLocationReplace)
{

    $( id ).dialog({
        autoOpen: true,
        modal: false,
        width: 600,
        draggable: true,
        resizable: false,
        closeOnEscape: false,
        buttons: [
            {
                text: "Cancel",
                click: function() {
                    // $( this ).dialog( "close" );
                    location.replace(buttonLocationReplace);
                }
            }
        ],
        open: function() {
            $(this).parent().find(".ui-dialog-titlebar-close").hide();
        },
        drag: function(event, ui) {
            var top = event.pageY - $(document).scrollTop();
            if (top < 0)
            {
                top = 0;
            }

            var maxTop = $(window).height() - $(this).parent().height();
            if (top > maxTop)
            {
                top = maxTop;
            }
            ui.position.top = top;
            // $(".ui-dialog").css("top", 400 + "px");
        }
    });
}

/**
 * @brief Making dialogs in center position while scrolling
 */
$(document).scroll(function (e) {

    if ($(".ui-widget-overlay")) //the dialog has popped up in modal view
    {
        //fix the overlay so it scrolls down with the page
        $(".ui-widget-overlay").css({
            position: 'fixed',
            top: '0'
        });

        //get the current popup position of the dialog box
        pos = $(".ui-dialog").position();

        //adjust the dialog box so that it scrolls as you scroll the page
        $(".ui-dialog").css({
            position: 'fixed'
        });
    }
});


/**
 * @brief Use string like string.format.
 */

function getStringFormatPlaceHolderRegEx(placeHolderIndex)
{
    return new RegExp('({)?\\{' + placeHolderIndex + '\\}(?!})', 'gm')
}

function cleanStringFormatResult(txt)
{
    if (txt == null) return "";
    return txt.replace(getStringFormatPlaceHolderRegEx("\\d+"), "");
}

String.prototype.format = function ()
{
    var txt = this.toString();
    for (var i = 0; i < arguments.length; i++)
    {
        var exp = getStringFormatPlaceHolderRegEx(i);
        txt = txt.replace(exp, (arguments[i] == null ? "" : arguments[i]));
    }
    return cleanStringFormatResult(txt);
}
