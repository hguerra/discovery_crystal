import './style.css'
import Events from './events';

function getCookie(name: any) {
  let end = 0;
  var dc = document.cookie;
  var prefix = name + "=";
  var begin = dc.indexOf("; " + prefix);
  if (begin == -1) {
    begin = dc.indexOf(prefix);
    if (begin != 0) return null;
  }
  else {
    begin += 2;
    end = document.cookie.indexOf(";", begin);
    if (end == -1) {
      end = dc.length;
    }
  }
  // because unescape has been deprecated, replaced with decodeURI
  //return unescape(dc.substring(begin + prefix.length, end));
  return decodeURI(dc.substring(begin + prefix.length, end));
}


function main() {
  const session = getCookie("_simulai_session");
  if (session) {
    window.location.href = 'https://querosimular.devpro.net.br/dashboard';
  }


  document.getElementById('btn-login')?.addEventListener('click', Events.onClickLogin);
  document.getElementById('btn-singup')?.addEventListener('click', Events.onClickLogin);
  document.getElementById('btn-get-started')?.addEventListener('click', Events.onClickLogin);
  document.getElementById('btn-simular')?.addEventListener('click', Events.onClickLogin);
}

document.addEventListener("DOMContentLoaded", main);
