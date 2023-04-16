function request() {
  var settings = {
    url: "http://localhost:8080/gateway/health/incidents.schema.json?auth_token=abc",
    method: "GET",
    timeout: 0,
  };

  $.ajax(settings).done(function (response) {
    console.log("cors liberado com sucesso.");
    console.log(response);
  });
}

function testCors() {
  console.log("cors-test");

  request();
}
