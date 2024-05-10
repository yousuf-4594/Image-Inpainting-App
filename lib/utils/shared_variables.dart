class SharedVariables{
  static String _url = "";

  static void setURL(String url){
    _url = url;
  }

  static String getURL(){
    return _url;
  }
}