## 变量

变量是程序的基本组成单位

先声明、赋值，再使用

```go
package main

import "fmt"

func main()  {
	//声明
	var i int
	//赋值
	i = 10
	//使用
	fmt.Println("i=",i)
}
```

使用注意事项

+ 变量是内存中的一个存储区域

+ 该区域有自己的名称（变量名）和类型（数据类型）

+ 变量使用的三种方式

  + 指定变量类型，声明后若不赋值，使用默认值
  + 根据值自行判断类型
  + 省略var 注意“:=”左边的变量不应该是声明过的

  ```go
  package main
  
  import "fmt"
  
  func main()  {
  	//第一种方式 不赋值 使用默认值
  	//声明
  	var i int
  	//使用
  	fmt.Println("i=",i)
  
  	//第二种 根据值自行判断类型
  	//声明 赋值
  	var num = 10.10
  	//使用
  	fmt.Println("num=",num)
  
  	//第三种 省略var 注意“:=”左边的变量不应该是声明过的
  	name:= "lihao"
  	fmt.Println("name=",name)
  }
  ```

+ 多变量声明

  ```go
  package main
  
  import "fmt"
  
  var (
  	sex="男"
  	age=20
  )
  
  func main()  {
  	//多变量声明
  	var i,j int
  	fmt.Println("i=",i,"j=",j)
  
  	//声明多个不同类型的变量
  	var a,name,b=1,"lihao",2 
  	fmt.Println("a=",a,"name=",name,"b=",b)
  
  	age,hobby:=18,"golang"
  	fmt.Println("age=",age,"hobby=",hobby)
  
  	 
  }
  ```

## 基本数据类型

### 字符串

```go
package main

import(
	"fmt"
)
func main()  {
	
	var luck=`var luck="福利彩票双色球中一等奖"
	fmt.Println("luck",luck)`

	//使用反引号，以字符串的原生形式输出
	fmt.Println(luck)
}
```

基本数据类型的默认值

```go
package main

import(
	"fmt"
)

func main()  {
	var i int
	var f1 float32
	var f2 float64
    var isMarry bool
	var name string
	//v表示按照变量原来的值输出,格式化输出Printf
	fmt.Printf("i=%d,f1=%f,f2=%f,isMarry=%v,name=%s",i,f1,f2,isMarry,name)

}
```

string和其他基本类型互转

```go
package main

import(
	"fmt"
	"strconv"
)

func main()  {
	var i int=886
	var name string="7777"
	//int转string
	var a string=strconv.Itoa(i)
	fmt.Printf("\n a的类型%T a=%v",a,a)
	//string转int64
	var b int64
	b,_=strconv.ParseInt(name,10,64)
	fmt.Printf("\n b的类型%T b=%v",b,b)
	//string转float
	var str3 = "100.64"
	var c float64
	c,_=strconv.ParseFloat(str3,64)
	fmt.Printf("\n c的类型%T c=%v",c,c)
}
```

