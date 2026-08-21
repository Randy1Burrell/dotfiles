snippet st "Input inling tags"
<${1:em}>some text</${1/(\w+).*/$1/}>
endsnippet

snippet t "Tags for files" b
<${1:div}>
</${1/(\w+).*/$1/}>
endsnippet

snippet func "Snippet for functions"
/**
 * @name $1
 * @desc
 * @ignore
 * @param  ex. {string[]} name - transcoding profile name
 * @return ex. {string}
 */
function ${1:function_name_here} (args) {
} // end of function $1
endsnippet

snippet af "Snippet for short notation of function"
/**
 * @name: $1
 * @desc:
 * @ignore:
 * @param:  ex. {string[]} name - transcoding profile name
 * @return: ex. {string}
 * @author: `echo $GITHUB_USER`
 */
const ${1:function_name_here} = (args) => {
} // end of function $1
endsnippet

snippet carrowfunc "Snippet for short notation of function"
/**
 * @name: $1
 * @desc:
 * @param:  ex. {string[]} name - transcoding profile name
 * @author: `echo $GITHUB_USER`
 */
${1:function_name_here} = (args) => {
  // do stuffs in $1
} // end of function $1

endsnippet

snippet cf "Snippet for short notation of function"
${1:function_name_here} () {
} // end of function $1

endsnippet

snippet constfunc "Snippet for long notation of defining a functions"
/**
 * @name: $1
 * @desc:
 * @ignore:
 * @param:  ex. {string[]} name - transcoding profile name
 * @return: ex. {string}
 * @author: `echo $GITHUB_USER`
 */
const ${1:function_name_here} = function (args) {
  // do stuffs in $1
} // end of function $1
endsnippet

snippet todo "description"
/**
 * TODO: ${1:desc}
 * Date: `!v strftime("%c")`
 * Author: `echo $GITHUB_USER`
 */
endsnippet

snippet c "A comment that spans multiple lines"
/**
 * ${1:Write your comments here}
 */
endsnippet

snippet cl "Insert normal class" b
/**
 * @name: ${1/(\w+).*/$1/}
 * @desc:
 * @ignore:
 * @param:  ex. {string[]} name - transcoding profile name
 * @return: ex. {string}
 * @author: `echo $GITHUB_USER`
 */
class ${1:ClassName}{
  constructor() {
  } // end constructor
}

export default ${1/(\w+).*/$1/}
endsnippet

snippet clr "Insert class for react" b
/**
 * @name: ${1/(\w+).*/$1/}
 * @desc:
 * @ignore:
 * @param:  ex. {string[]} name - transcoding profile name
 * @return: ex. {string}
 * @author: `echo $GITHUB_USER`
 */
class ${1:ClassName} extends Component {
  constructor(props) {
    super(props);
    this.state = {}
  } // end constructor

  render() {
    return (
      <${1:div}>
      </${1/(\w+).*/$1/}>
    );
  }
}

export default ${1/(\w+).*/$1/}
endsnippet

snippet ren "Input render function" b
render() {
  return (
    <${1:div}>
    </${1/(\w+).*/$1/}>
  );
}
endsnippet

snippet imp "Inputs import statement" b
import ${1:impoert?} from "CHANGE ME!!!"
endsnippet

snippet impm "Inputs import statement" b
import {
${1:impoert?}
} from "CHANGE ME!!!"
endsnippet
