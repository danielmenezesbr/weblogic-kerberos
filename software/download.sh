export ORACLE_SSO_USERNAME=${ORACLE_SSO_USERNAME}
export ORCL_PWD=${ORCL_PWD}

echo $ORACLE_SSO_USERNAME
echo $ORCL_PWD

cd /software
pwd

if [ -z "$ORACLE_SSO_USERNAME" ] || [ -z "$ORCL_PWD" ]
then
  echo "\$ORACLE_SSO_USERNAME or/and \$ORACLE_SSO_USERNAME is empty";
  exit 0;
else
  [ -f fmw_12.2.1.2.0_wls_Disk1_1of1.zip ] || wget -O - -q https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | \
          bash -s -- --cookie=accept-weblogicserver-server \
                  --username=$ORACLE_SSO_USERNAME \
          http://download.oracle.com/otn/nt/middleware/12c/12212/fmw_12.2.1.2.0_wls_Disk1_1of1.zip;
  [ -f jdk-8u151-linux-x64.tar.gz ] || wget -O - -q https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | \
          bash -s -- --cookie=accept-weblogicserver-server \
                  --username=$ORACLE_SSO_USERNAME \
          https://download.oracle.com/otn/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.tar.gz;
  [ -f jce_policy-8.zip ] || wget \
                        --no-cookies \
                        --no-check-certificate \
                        --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
                        -O jce_policy-8.zip \
                        http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip;
  unzip fmw_12.2.1.2.0_wls_Disk1_1of1.zip;
  ls -la;
fi