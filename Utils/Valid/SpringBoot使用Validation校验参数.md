## 准备工作

引入相关依赖：

```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
```
注：测试时，还引入了lombok、SpringBoot的web、test等基础依赖

# 约束性注解(简单)说明

```basic
validator内置注解：
@Null 被注释的元素必须为 null
@NotNull 被注释的元素必须不为 null
@AssertTrue 被注释的元素必须为 true
@AssertFalse 被注释的元素必须为 false
@Min(value) 被注释的元素必须是一个数字，其值必须大于等于指定的最小值
@Max(value) 被注释的元素必须是一个数字，其值必须小于等于指定的最大值
@DecimalMin(value) 被注释的元素必须是一个数字，其值必须大于等于指定的最小值
@DecimalMax(value) 被注释的元素必须是一个数字，其值必须小于等于指定的最大值
@Size(max, min) 被注释的元素的大小必须在指定的范围内
@Digits (integer, fraction) 被注释的元素必须是一个数字，其值必须在可接受的范围内
@Past 被注释的元素必须是一个过去的日期
@Future 被注释的元素必须是一个将来的日期
@Pattern(value)被注释的元素必须符合指定的正则表达式
Hibernate Validator 附加的注解：
@Email 被注释的元素必须是电子邮箱地址
@Length 被注释的字符串的大小必须在指定的范围内
@NotEmpty 被注释的字符串的必须非空
@Range 被注释的元素必须在合适的范围内
@NotBlank 验证字符串非null，且长度必须大于0
```

## @Validated与@Valid的简单对比说明

​        @Valid注解与@Validated注解功能大部分类似；两者的不同主要在于:@Valid属于javax下的，而@Validated属于spring下；@Valid支持嵌套校验、而@Validated不支持，@Validated支持分组，而@Valid不支持。

## 自定义注解

​        虽然Bean Validation和Hibernate Validator已经提供了非常丰富的校验注解，但是在实际业务中，难免会碰到一些现有注解不足以校验的情况；这时，我们可以考虑自定义Validation注解

**创建自定义注解**

```java
import com.aspire.constraints.impl.JustryDengValidator;
 
import javax.validation.Constraint;
import javax.validation.Payload;
import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.Target;
 
import static java.lang.annotation.ElementType.FIELD;
import static java.lang.annotation.ElementType.PARAMETER;
import static java.lang.annotation.RetentionPolicy.RUNTIME;
 
/**
 * 自定义校验注解
 * 提示:
 *     1、message、contains、payload是必须要写的
 *     2、还需要什么方法可根据自己的实际业务需求，自行添加定义即可
 *
 * 注:当没有指定默认值时，那么在使用此注解时，就必须输入对应的属性值
 *
 * @author JustryDeng
 * @date 2019/1/15 1:17
 */
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
@Documented
// 指定此注解的实现，即:验证器
@Constraint(validatedBy ={JustryDengValidator.class})
public @interface ConstraintsJustryDeng {
 
    // 当验证不通过时的提示信息
    String message() default "JustryDeng : param value must contais specified value!";
 
    // 根据实际需求定的方法
    String contains() default "";
 
    // 约束注解在验证时所属的组别
    Class<?>[] groups() default { };
 
    // 负载
    Class<? extends Payload>[] payload() default { };
}
```

## AOP异常处理

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.validation.BindException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
 
import javax.validation.ConstraintViolationException;
import javax.validation.ValidationException;
import java.util.HashMap;
import java.util.Map;
 
/**
 * SpringMVC统一异常处理
 *
 * @author JustryDeng
 * @date 2019/10/12 16:28
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
 
    /**
     * 处理Validated校验异常
     * <p>
     * 注: 常见的ConstraintViolationException异常， 也属于ValidationException异常
     *
     * @param e
     *         捕获到的异常
     * @return 返回给前端的data
     */
    @ResponseStatus(code = HttpStatus.BAD_REQUEST)
    @ExceptionHandler(value = {BindException.class, ValidationException.class, MethodArgumentNotValidException.class})
    public Map<String, Object> handleParameterVerificationException(Exception e) {
        log.error(" handleParameterVerificationException has been invoked", e);
        Map<String, Object> resultMap = new HashMap<>(4);
        resultMap.put("code", "100001");
        String msg = null;
        /// BindException
        if (e instanceof BindException) {
            // getFieldError获取的是第一个不合法的参数(P.S.如果有多个参数不合法的话)
            FieldError fieldError = ((BindException) e).getFieldError();
            if (fieldError != null) {
                msg = fieldError.getDefaultMessage();
            }
        /// MethodArgumentNotValidException
        } else if (e instanceof MethodArgumentNotValidException) {
            BindingResult bindingResult = ((MethodArgumentNotValidException) e).getBindingResult();
            // getFieldError获取的是第一个不合法的参数(P.S.如果有多个参数不合法的话)
            FieldError fieldError = bindingResult.getFieldError();
            if (fieldError != null) {
                msg = fieldError.getDefaultMessage();
            }
        /// ValidationException 的子类异常ConstraintViolationException
        } else if (e instanceof ConstraintViolationException) {
            /*
             * ConstraintViolationException的e.getMessage()形如
             *     {方法名}.{参数名}: {message}
             *  这里只需要取后面的message即可
             */
            msg = e.getMessage();
            if (msg != null) {
                int lastIndex = msg.lastIndexOf(':');
                if (lastIndex >= 0) {
                    msg = msg.substring(lastIndex + 1).trim();
                }
            }
        /// ValidationException 的其它子类异常
        } else {
            msg = "处理参数时异常";
        }
        resultMap.put("msg", msg);
        return resultMap;
    }
    
}

```

