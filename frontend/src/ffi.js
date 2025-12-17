export function get_cookies() {
    return document.cookie;
}

export function set_cookie(key, value) {
    let now = new Date();
    now.setSeconds(now.getSeconds() + 60 * 60);
    document.cookie = "" + key + "=" + value + "; expires=" + now.toUTCString();

    setTimeout(() => set_cookie(key, value), 59 * 60);
}
