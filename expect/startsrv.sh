#/bin/bash

LOG_DIR=$1
[ "${LOG_DIR}" == "" ] && LOG_DIR="latest"

WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}/log/${LOG_DIR}

pwd

#generate result html page
LINE=""
for i in $(ls *.log)
do
    LINE=${LINE}$(echo -e "<li><a href='javascript:;' class='item'>$i</a>\r\n")
done

cp ${WORKDIR}/script/jquery.min.js ${WORKDIR}/log/${LOG_DIR}

cat > list.html <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
<title>host list</title>
<head>
<script type="text/javascript" src="/jquery.min.js"></script>
<script language="javascript">
  \$(document).ready(function() {
    \$(".item").click(function(event) {
      var logfile = "/"+event.target.text + "?" + (new Date().getTime());
      \$.get( logfile , function(data) {
        //title
        var title = parent.frames["content"].document.getElementById('title');
        \$(title).html(event.target.text);
        //content
        var container = parent.frames["content"].document.getElementById('container');
        \$(container).html(data);
      }, 'text');
    });
  });
</script>
</head>
<body>
<h2>host list</h2>
<hr>
<ul>
$(echo $LINE)
</ul>
<hr>
</body>
</html>
EOF

cat > content.html <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
<title>log content</title>
<body>
<div id="title"></div>
<textarea id="container" style="margin: 0px; height: 100%; width: 100%;" ></textarea>
</body>
</html>
EOF

cat > index.html <<EOF
<!DOCTYPE html>
<html>
<frameset cols="250,*">
  <frame src="/list.html" >
  <frame name="content" id="content" src="/content.html" >
</frameset>
</html>
EOF

#start web server
python ${WORKDIR}/script/httpsrv.py
