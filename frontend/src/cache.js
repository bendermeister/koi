export function cache_set(key, value) {
    localStorage.setItem(key, value);
}

export function cache_get(key) {
    let item = localStorage.getItem(key);
    if (item == null) {
        return "";
    }
    return item;
}
