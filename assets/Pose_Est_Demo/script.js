
const videoElement = document.getElementsByClassName('input_video')[0];
const canvasElement = document.getElementsByClassName('output_canvas')[0];
const canvasCtx = canvasElement.getContext('2d');

var FPS, avgFPS, currentTime,lastTime =0;


var updateFPS = false;

var intervalId = window.setInterval(function(){
    updateFPS = true;
}, 1000);

var timesOnResultsRan = 0; 
var FPSTotal =0;


function onResults(results) {
    
    currentTime = performance.now();
    FPS = Math.round(1000*(1/(currentTime-lastTime)));
    timesOnResultsRan++; 
    FPSTotal += FPS;
    avgFPS = Math.round(FPSTotal/timesOnResultsRan);
    if(updateFPS){
        
        document.getElementById('fps').innerHTML = "FPS: " + FPS + " Average FPS: " + avgFPS;
        updateFPS = false;
    }
    lastTime = currentTime;
    

    if (!results.poseLandmarks) {
        return;
    }

    canvasCtx.save();
    canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
    canvasCtx.drawImage(
        results.image, 0, 0, canvasElement.width, canvasElement.height);
    drawConnectors(canvasCtx, results.poseLandmarks, POSE_CONNECTIONS,
        { color: '#00FF00', lineWidth: 2.0 });
    drawLandmarks(canvasCtx, results.poseLandmarks,
        { color: '#FF0000', lineWidth: 1.0 });
    canvasCtx.restore();
}

const pose = new Pose({
    locateFile: (file) => {
        return `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`;
    }
});
pose.setOptions({
    modelComplexity: 1,
    smoothLandmarks: true,
    minDetectionConfidence: 0.5,
    minTrackingConfidence: 0.5
});

pose.onResults(onResults);

const camera = new Camera(videoElement, {
    onFrame: async () => {  
        await pose.send({ image: videoElement });
    }
});
camera.start();
