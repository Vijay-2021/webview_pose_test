const videoElement = document.getElementsByClassName('input_video')[0];
const canvasElement = document.getElementsByClassName('output_canvas')[0];
const canvasCtx = canvasElement.getContext('2d');
const FPSElement = document.getElementById('fps');
var FPS, avgFPS, currentTime,lastTime =0;
var updateFPS = false;
var timesOnResultsRan = 0; 
var FPSTotal =0;
var videoState = false;//false = webcam not playing, true = webcam playing
const intervalId = window.setInterval(function(){updateFPS = true;}, 1000);
function onResults(results) {
    currentTime = performance.now();
    FPS = Math.round(1000*(1/(currentTime-lastTime)));
    timesOnResultsRan++; 
    FPSTotal += FPS; 
    avgFPS = Math.round(FPSTotal/timesOnResultsRan);
    if(updateFPS){
        FPSElement.innerHTML = "FPS: " + FPS + " Average FPS: " + avgFPS; updateFPS = false;
    }
    lastTime = currentTime;
    //canvasCtx.save();
    canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
    canvasCtx.drawImage(results.image, 0, 0, canvasElement.width, canvasElement.height);
    if(!results.poseLandmarks){return;}//if there are no pose landmarks don't draw them
    drawConnectors(canvasCtx, results.poseLandmarks, POSE_CONNECTIONS,{ color: '#00FF00', lineWidth: 2.0 });
    drawLandmarks(canvasCtx, results.poseLandmarks,{ color: '#FF0000', lineWidth: 1.0 });
    //canvasCtx.restore();
}
const pose = new Pose({
    locateFile: (file) => {
        return `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`;
    }
});
pose.setOptions({
    modelComplexity: 0,
    smoothLandmarks: true,
    minDetectionConfidence: 0.5,
    minTrackingConfidence: 0.5
});
pose.onResults(onResults);
var sentResizedMessage = false;
const camera = new Camera(videoElement, {
    onFrame: async () => {
        await pose.send({ image: videoElement });
        if(!sentResizedMessage){
            console.log("Message: resize video");
            sentResizedMessage = true;
        }
    }
});
//camera.start()
$('#startEst').click(function(){
    //if this is pressed too much accidentally, it lags the app, so only let the camera be started if it is not playing
    if(!videoState){
        camera.start();
        videoState=true;
    }
});
$('#stopEst').click(function(){
    if(videoState){
        const stream = videoElement.srcObject;
        const tracks = stream.getTracks();
        tracks.forEach(function(track) {
            track.stop();
        });
        videoElement.srcObject = null;
        canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
        videoState = false;
    }
});
