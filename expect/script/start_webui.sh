#/bin/bash

LOG_FULLPATH=$1
[ "${LOG_FULLPATH}" == "" ] && LOG_FULLPATH="latest"

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
cd ${LOG_FULLPATH}

pwd

#generate result html page
LINE=""
for i in $(ls *.log)
do
    LINE=${LINE}$(echo -e "<li><a href='javascript:;' class='move'>$i</a></li>\r\n")
done

cp ${WORKDIR}/webui/js/jquery.min.js ${LOG_FULLPATH}
cp ${WORKDIR}/webui/assets/fixedsys.ttf ${LOG_FULLPATH}

cat > list.html <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
<title>log list</title>
<head>
<style>
  @font-face {
      font-family: fixedsys;
      src: url('fixedsys.ttf');
  }
  body {
    background-color: black;
    font-family: fixedsys;
    font-size:1em;
  }
  .highlight {
      color: #00ff00;
      background-color: black;
      #font-weight: bold;
  }
</style>
<script type="text/javascript" src="/jquery.min.js"></script>
<script language="javascript">
  \$(document).ready(function() {
    var classHighlight = 'highlight';
    var \$li = \$('li'),
    \$move = \$(".move").click(function (event) {
        var logfile = "/"+event.target.text + "?" + (new Date().getTime());
        \$.get( logfile , function(data) {
          //title
          var title = parent.frames["content"].document.getElementById('title');
          \$(title).html(event.target.text);
          //content
          var container = parent.frames["content"].document.getElementById('container');
          \$(container).html(data);
        }, 'text');
        //focus style
        this.focus();
        \$move.removeClass(classHighlight);
        \$(this).addClass(classHighlight);
    });
    //support keyboard
    \$(document).keydown(function(e) {
        if (e.keyCode == 40 || e.keyCode == 38) {
            var inc = e.keyCode == 40 ? 1 : -1,
                move = \$move.filter(":focus").parent('li').index() + inc;
            \$li.eq(move % \$li.length).find('.move').click();
        }
    });
    \$move.filter(':first').click();
  });
</script>
</head>
<body>
<div style="color: white; text-align: center;"> log list</div>
<hr>
<ul>
$(echo $LINE)
</ul>
</body>
</html>
EOF

cat > content.html <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
<title>log content</title>
<head>
<style type="text/css">
  @font-face {
      font-family: fixedsys;
      src: url('fixedsys.ttf');
  }
  body {
    background-color: black;
    font-family: fixedsys;
    font-size:1em;
  }
</style>
</head>
<body>
<div id="title" style="color: white; text-align: center;" ></div>
<textarea id="container" style="margin: 0px; height: 100%; width: 100%; font-family: fixedsys; font-size:1em; background-color: black; color: #00ff00;" ></textarea>
</body>
</html>
EOF

cat > index.html <<EOF
<!DOCTYPE html>
<html>
<frameset cols="220,*" frameborder=NO framespacing=0 border=0 >
  <frame src="/list.html" >
  <frame name="content" id="content" src="/content.html" >
</frameset>
</html>
EOF

#start web server
python ${WORKDIR}/script/httpsrv.py
