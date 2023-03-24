//const API_URL = 'https://rd0y8fbsyd.execute-api.us-east-1.amazonaws.com/dev ';
const API_URL = 'https://nqx9h20zdl.execute-api.us-east-1.amazonaws.com/devTerraform/{proxy+}';

// Get the current visitor count from the backend API
fetch(API_URL)
  .then(response => response.json())
  .then(data => {

    console.log(data); // Debugging line
    const counter = data.Count; // Assigning the count value to the counter variable
    const counterElement = document.getElementById('counter');
    counterElement.textContent = counter;
  })
  .catch(error => {
    console.error(error);
  });