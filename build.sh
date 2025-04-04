#!/bin/bash



echo -n "
Please Choose from the following images:  

  1. win10_22h2
  2. win11_23h2
  3. win2019
  4. win2022

Select the image you want to build (1-4): 
"
read OS

# Case Statement to install one of the above images:
case $OS in
  1)
    echo "You have chosen win10_22h2"
    export OS=win10_22h2
    ;;
  2)
    echo "You have chosen win11_23h2"
    export OS=win11_23h2
    ;;
  3)
    echo "You have chosen win2019"
    export OS=win2019
    ;;
  4)
    echo "You have chosen win2022"
    export OS=win2022
    ;;
  *)
    echo "Invalid option. Please choose a valid image."
    exit 1
    ;;
esac

# Check if the OS variable is set
if [ -z "$OS" ]; then
  echo "OS variable is not set. Exiting."
  exit 1
fi

# Check if the OS variable is set to a valid value
if [[ "$OS" != "win11_23h2" && "$OS" != "win10_22h2" && "$OS" != "win2019" && "$OS" != "win2022" ]]; then
  echo "Invalid OS value. Exiting."
  exit 1
fi

echo "Initialize Packer Environment"
echo ""
packer init ./${OS}.pkr.hcl
echo ""

echo "Building Packer Image ${OS}"
echo ""
PACKER_LOG=1 packer build ./${OS}.pkr.hcl
echo ""
