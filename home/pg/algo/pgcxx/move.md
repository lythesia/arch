
###lvalue and rvalue

>C++03 3.10/1 says: “Every expression is either an lvalue or an rvalue.”  It’s important to remember that lvalueness versus rvalueness is a property of expressions, not of objects.

>Lvalues name objects that persist beyond a single expression.  For example, obj , *ptr , ptr[index] , and ++x are all lvalues.

>Rvalues are temporaries that evaporate at the end of the full-expression in which they live (“at the semicolon”).  For example, 1729 , x + y , std::string(“meow”) , and x++ are all rvalues.

lvalue: **persisted**  **named**  `& operator`  
rvalue: **temporary**

####mutability
* `string s1("hello")` modifiable lvalue
* `const string s2("hello")` const lvalue
* `string s3(){ return "hello"; }` modifiable rvalue
* `const string s4() { return "hello"; }` const rvalue

```cpp
string(string&& other) {
  // do something..
  *this = other; // wrong, "operator=(const string&)" invoked, not "move semantic"
  // *this = std::move(other); // ok
}
```

***attention: *** does `modifiable rvalue` make sense?

####reference
|reference  |modifiable lvalue|const lvalue|modifiable rvalue|const rvalue|
|-----------|:---------------:|:----------:|:---------------:|:----------:|
|Type&      |yes              |*anti-const*|*danger*         |*anti-const&danger*|
|const Type&|yes              |yes         |yes              |yes         |

####reference collapsing
>References to references are collapsed in C++0x, and the reference collapsing rule is that “lvalue references are infectious”. 

* T& & = T&
* T&& & = T&
* T& && = T&
* T&& && = T&
