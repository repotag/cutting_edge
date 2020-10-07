window.addEventListener( "load", function () {
  
  function showError(message) {
    form_group = document.getElementById( "token-form-group" );
    form_group.classList.add( "errored" );
    document.getElementById( "token-input-validation" ).innerText = message;
  }
  
  function insertHiddenRepos(partial) {
    div = document.getElementById( "hidden-repos" );
    div.innerHTML = partial;
  }
  
  function sendToken() {
    
    xhr = new XMLHttpRequest();
    formData = new FormData( form );
    
    xhr.addEventListener( "load", function(event) {
      if (xhr.status == 401) {
        showError('Incorrect token.');
      } else if (xhr.status == 200) {
        partial = JSON.parse(event.target.responseText)['partial'];
        insertHiddenRepos(partial);
      }
    } );
    
    xhr.addEventListener( "error", function( event ) {
      showError('Unknown server error occurred during the processing of your token.');
    } );
    
    xhr.open( "POST", "/hidden_repos" );
    xhr.setRequestHeader("Content-Type", "application/json");
    
    data = {};
    formData.forEach(function(value, key){
      data[key] = value;
    });
    var json = JSON.stringify(data);
    
    xhr.send( json );

  }
  
  const form = document.getElementById( "token-form" );

  form.addEventListener( "submit", function ( event ) {
    event.preventDefault();

    sendToken();
  } );
  
} );