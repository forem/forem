

function browserStoreCache(action,userData) {
  try {
    if (action === "set") {
      localStorage.setItem("current_user",userData);
    }
    else if (action === "remove") {
      localStorage.removeItem("current_user");
    }
    else {
      return localStorage.getItem("current_user");
    }
  }
  catch(err) {
      browserStoreCache("remove");
  }
}
