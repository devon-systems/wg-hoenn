let
  prefixLength = 24;
  listenPort = 51821;
in {
  inherit prefixLength listenPort;
  subnet = "10.254.1.0/${toString prefixLength}";
  domain = "hoenn";
  hub = "sunnyshore";
  endpoint = "40.160.83.152:${toString listenPort}";
  nodes = {
    sunnyshore = {
      address = "10.254.1.1";
      publicKey = "vinYIK2laJ19yVMlw6iB5lb9+wY8ZBrM+Y4nrBmMxxQ=";
    };

    mauville = {
      address = "10.254.1.2";
      publicKey = "DLphP2R9EJ2TbIgaabt5ExQ461TdYX2EjlMsphxkVj8=";
    };

    rustboro = {
      address = "10.254.1.3";
      publicKey = "ZhpSQzxRmKrp3Tsny9rGP1PCtcP/zghdRoQJBPWPGGQ=";
    };

    sootopolis = {
      address = "10.254.1.4";
      publicKey = "ezW8vZQUpvcb2ltr8BOIn+iZ/lXI0mvNLs49ZiaZnCA=";
    };

    verdanturf = {
      address = "10.254.1.5";
      publicKey = "Grk570okUSWaxah004BUIEbul5IyjDsaoRgYV0fu0ho=";
    };

    petalburg = {
      address = "10.254.1.8";
      publicKey = "sodFLJVrTVsifP5ltziHkQrWDwEj+3Cvj6csZbWtgEE=";
    };

    lavaridge = {
      address = "10.254.1.10";
      publicKey = "++8uCYxO+H6bu075TlaTxK2qnu7jvt91DwX4vymLUHs=";
    };

    lilycove = {
      address = "10.254.1.9";
      publicKey = "0FG8r6ua2z+o3etlbtmqql8dOu9T48Bx/PzBmSgv+kA=";
    };
  };
}
