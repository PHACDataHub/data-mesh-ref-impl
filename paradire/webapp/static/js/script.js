const SERVER_CHECK_INTERVAL = 60000;
const SERVER_ENDPOINT = '/health_check';
let isUploading = false;
let healthCheckInterval;

function checkServerStatus() {
    if (isUploading) {
        return;  // Skip the health check if data is being uploaded
    }

    $.ajax({
        url: SERVER_ENDPOINT,
        type: 'GET',
        success: function (response, textStatus) {
            if (textStatus === "success") {
                $('#status-text').text('FHIR server is up and running.');
            } else {
                $('#status-text').text('FHIR server is down.');
            }
        },
        error: function (jqXHR, textStatus, errorThrown) {
            $('#status-text').text('FHIR server is down.');
            console.log('Error:', textStatus, errorThrown);
        }
    });
}

healthCheckInterval = setInterval(checkServerStatus, SERVER_CHECK_INTERVAL);
checkServerStatus();

$('#upload-form').on('submit', function(e) {
    e.preventDefault();

    let formData = $(this).serialize();

    $('#uploading-spinner').removeClass('d-none');  // Show the spinner
    $('#uploading-province').text('Uploading data for ...');  // Show the text
    isUploading = true;

    // Stop the health check while uploading
    clearInterval(healthCheckInterval);

    $.ajax({
        type: 'POST',
        url: '/',
        data: formData,
        dataType: 'json',
        success: function(response) {
            isUploading = false;
            $('#uploading-spinner').addClass('d-none');  // Hide the spinner
            $('#uploading-province').empty(); // Clear the content of #uploading-province
            
            console.log("AJAX success:", response); // Debugging
            
            response.results.forEach(function(result) {
                if (result.status === 'success') {
                    $('#uploading-province').append($('<div>').text('Data uploaded successfully for ' + result.province + '.'));
                } else {
                    $('#uploading-province').append($('<div>').text('Error uploading data for ' + result.province + '.'));
                }
            });

            // Resume the health check after uploading completes
            healthCheckInterval = setInterval(checkServerStatus, SERVER_CHECK_INTERVAL);
        },
        error: function(xhr, status, error) {
            isUploading = false;
            $('#uploading-spinner').addClass('d-none');  // Hide the spinner
            $('#uploading-province').text('An error occurred: ' + error);
            
            console.error("AJAX error:", error); // Debugging

            // Resume the health check after an error
            healthCheckInterval = setInterval(checkServerStatus, SERVER_CHECK_INTERVAL);
        }
    });
});
