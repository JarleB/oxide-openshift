#!/bin/bash

set -eo pipefail

function usage {
  echo "Usage: $0 <install-config> <installer_directory> <s3-bucket>"
}

if [[ -z $3 ]]
then
  usage
  exit 1
fi

installer_dir=$2
install_config=$1
ignition_bucket=$3

if ! openshift-install --help 2>&1 > /dev/null 
then
  echo "Please install openshift installer for the cluster version you want to provision"
  exit 1
fi

if [[ ! -f ${install_config} ]]
then
  echo "File \"${install_config}\" does not exsistxs. Please give us an openshift install config"
  exit 1
fi

if [[ -d ${installer_dir} ]]
then
  echo "Directory \"${installer_dir}\" exsists. Please give us a new destinastion, or remove the old"
  exit 1
fi

echo "Testing bucket write access to s3://${ignition_bucket}/"

if ! aws s3 cp $0 s3://${ignition_bucket}/ 2>&1 > /dev/null 
then
  echo "Unable to upload to aws s3 bucket. Please make sure awscli is installed and configured, bucket exists and is writable for new objects"
  echo "The ignition files in the bucket must be available for download by your preconfigured images using kernel boot parameter \"ignition.config.url\" "
  exit 1
fi

echo "Removing test object s3://${ignition_bucket}/$0"
aws s3 rm s3://${ignition_bucket}/$0

function refresh_boot_ignition {
  aws s3 cp ${installer_dir}/bootstrap.ign s3://$1/
  aws s3 cp ${installer_dir}/master.ign s3://$1/
  aws s3 cp ${installer_dir}/worker.ign s3://$1/
}




mkdir $2
echo "Copying \"${install_config}\" to directory \"${installer_dir}\""
cp ${install_config} ${installer_dir}
echo "Running openshift-install create manifests --dir=${installer_dir}"
openshift-install create manifests --dir=${installer_dir}
echo "Running openshift-install  create ignition-configs --dir=${installer_dir}"
openshift-install  create ignition-configs --dir=${installer_dir}

echo "Uploading ignition files to bucket s3://${ignition_bucket}/"
refresh_boot_ignition ${ignition_bucket}

echo "Ignition configs successfully created and uploaded. Time deploy boot and master nodes"

