---
layout: post
title: "基于java反射实现android的orm框架"
date: 2017-06-29 18:22:00
categories: android
author: andyqtchen
tags: orm android
---

* content
{:toc}

| 导语
java反射机制是一个很好用的东西。反射机制可以帮我们做那些重复的有规则的事情，所以现在很多的自动生成代码的软件就是运用反射机制来完成的。这里重复造个轮子看看。

# 1\. 框架设计

<!--more-->
## 1.1. 总体流程

![](/image/ji_yu_java_fan_she_shi_xian_android_de_orm_kuang_jia/65d745851b21df0033d471c5711a9250c21d1764455fab9d4a507932978fa721)

>   1. 对于数据库的“增删改”操作，将对象输入，通过orm框架处理，构建sql语句，然后写入数据库，如图1所示；

>   2. 对于查询数据库的操作，输入要输出对象的class，通过orm框架处理，构建sql语句，查询数据库，返回后构建成object输出，如图2所示；

>

## 1.2. orm内部实现流程

![](/image/ji_yu_java_fan_she_shi_xian_android_de_orm_kuang_jia/6feb82d370385ce74029dc2663bd3bf95a6d54cec65665ef39b4e0d292abf3b2)

> 构建sql语句的原理：通过java反射机制，获取class的字段和object字段值，通过字符串拼接构建sql。

## 1.3. java数据类型与sqlite数据类型映射表

java数据类型 | sqlite数据类型  
---|---  
int、integer、byte、byte、short、short、long、long、boolean、boolean | integer  
float、float、double、double | real  
date | date  
string | text  
  
> ps：这里简单起见，将所有的字符串都用text；整数都用integer；

# 2\. 内部实现的几个重要实现规则

#### 1\. 对于sqlite表字段与java对象字段映射规则：

（1）只映射非`final`和非`static`的java字段；  
（2）java的字段名即sqlite表的字段名；  
（3）主键取java对象中的名字为id（不区分大小写）或者加了`[@id](https://github.com/id "@id"
)`注解的字段，优先查找注解；

#### 2\. 保存数据类型规则：

（1）以java基本数据类型以及其包装类为主，还有`date`；对于其他类不做处理；

#### 3\. 表名称生成规则：

（1）以java类的完全限定名来命名（`.`替换为`_`），例如：`com.andy.person`的代表的表名为`com_andy_person`，保证了表名的唯一性；

# 3\. 代码实现

介绍一下几个重要的类  
（1） 用于构造sql语句的类`sqlbuilder`（主要用了java反射机制）  
（2） 用于执行sql语句的类`sqlitedbexecutor`  
（3） 提供给外部使用的orm主类`lazydb`

## 3.1 sqlbuilder：sql语句构建器

> 该class的主要作用是，将外部传进来的object（对象）或者class（类），通过java反射机制，构建成sql语句。

#### 这里以创建表的sql为例

> 代码步骤分解：  
> （1）取出class中所有field，即field数组；  
> （2）遍历field数组，找出主键的field，拼到sql的字符串里；  
> （3）再次遍历field数组，过滤掉主键的field、final、static，拼到sql的字符串里；

具体代码如下：

    
    
        // sqlbuilder类
        /**
         * 构建创建数据库表的sql语句
         *
         * @param clazz 类
         * @return 创建表的sql语句
         */
        public static string buildcreatetablesql(class> clazz) {
            stringbuilder sb = new stringbuilder();
    
            field[] fields = reflectutil.getdeclaredfields(clazz);
            if (fields == null || fields.length == 0) {
                throw new illegalstateexception("class'fields can not be empty");
            }
    
            // 开头
            sb.append("create table ")
                    .append(tableutil.gettablename(clazz)) // tablename
                    .append("(");
            // 找到主键
            field idfield = idutil.getidfield(fields);
            if (idfield != null) {
                string idcolumn = idfield.getname();
                id id = idfield.getannotation(id.class);
                // 判断是有没有注解的
                if (id != null && !"".equals(id.column())) {
                    idcolumn = id.column();
                }
                datatype datatype = tableutil.getdatatype(idfield.gettype());
                sb.append(idcolumn)
                        .append(" ")
                        .append(datatype.tostring())
                        .append(" primary key")
                        .append(",");
            }
            for (field field : fields) {
                if (modifier.isstatic(field.getmodifiers()) || modifier.isfinal(field.getmodifiers())) {// 移除是final和static的字段
                    continue;
                }
                // 让不是id的field进来
                if (field != idfield) {
                    sb.append(field.getname())
                            .append(" ")
                            .append(tableutil.getdatatype(field.gettype()))
                            .append(",");
                }
            }
            // 除去最后一个逗号
            if (sb.charat(sb.length() - 1) == ',') {
                sb.deletecharat(sb.length() - 1);
            }
            sb.append(")");
            string sql = sb.tostring();
            // debug log
            debuglogger.d("createtablesql", sql);
            return sql;
        }
    

**上面代码中用到了几个工具类：**  
`reflectutil`：用于java反射的工具类，将所有反射调用的方法都放到这里来，统一管理，方便优化处理；  
`idutil`：用于主键field查找的工具类；  
`tableutil`：用于数据库表字段数据与java数据类型转换、表名生成等；

## 3.2 sqlitedbexecutor：sql语句执行器

> 该class的主要作用是，用于执行sql语句，或者通过`sqliteopenhelper`执行一些数据库操作，反正所有数据库操作都在这里面。

（1）数据库非查询操作

    
    
        // sqlitedbexecutor类
        /**
         * 执行非查询操作事物
         *
         * @param operation 非查询操作
         */
        public void executetransaction(noqueryoperation operation) throws exception {
            sqlitedatabase db = helper.getwritabledatabase();
            try {
                db.begintransaction();
                debuglogger.d("noquery", "begintransaction");
                if (operation != null) {
                    operation.onoperation(db);
                }
                db.settransactionsuccessful();
                debuglogger.d("noquery", "transactionsuccessful");
            } finally {
                db.endtransaction();
                debuglogger.d("noquery", "endtransaction");
            }
        }
    
        public interface noqueryoperation {
            void onoperation(sqlitedatabase db) throws exception;
        }
    
        /**
         * 执行sql，非查询操作
         * @param sql sql语句
         * @throws exception
         */
        public void execsql(final string sql) throws exception {
            executetransaction(new noqueryoperation() {
                @override
                public void onoperation(sqlitedatabase db) throws exception {
                    db.execsql(sql);
                }
            });
        }
    

（2）数据库查询操作

    
    
        // sqlitedbexecutor类
        public cursor rawquery(string sql, string[] selectionargs) {
            sqlitedatabase db = helper.getreadabledatabase();
            return db.rawquery(sql, null);
        }
    

然后看一段比较好看的查询代码：

    
    
            list entities = lazydb
                    .query(entity.class)
                    .selectall()
                    .where("id=? and name=? and age=? and birthday=? and sex=? and money=?",
                            entity.getid(),
                            entity.getname(),
                            entity.getage() + "",
                            dateutil.date2string(entity.getbirthday()),
                            entity.issex() ? "1" : "0",
                            double.tostring(entity.getmoney())
                    )
                    .findall();
    

> 个人比较钟意这种构建器模式下的代码；看下查询代码，基于builder模式的实现。

    
    
    public class selectbuilder<t> {
        private final sqlitedbexecutor executor;
    
        final class objectclass;
        string[] columns;
        string wheresection;
        string[] whereargs;
    
        string having;
        string orderby;
        string groupby;
        string limit;
    
        public selectbuilder(sqlitedbexecutor executor, class clazz) {
            this.objectclass = clazz;
            this.executor = executor;
        }
    
        public selectbuilder selectall() {
            return this;
        }
    
        public selectbuilder select(string... columns) {
            this.columns = columns;
            return this;
        }
    
        public selectbuilder where(string wheresection, string... whereargs) {
            this.wheresection = wheresection;
            this.whereargs = whereargs;
            return this;
        }
    
        public selectbuilder having(string having) {
            this.having = having;
            return this;
        }
    
        public selectbuilder orderby(string orderby) {
            this.orderby = orderby;
            return this;
        }
    
        public selectbuilder groupby(string groupby) {
            this.groupby = groupby;
            return this;
        }
    
        public selectbuilder limit(string limit) {
            this.limit = limit;
            return this;
        }
        ......
    }
    

> 提供了类似写sql查询语句的字符串构建器；  
> 最后，执行查询；

    
    
    public class selectbuilder<t> {
        ......
    
        /**
         * 执行查询操作，获取查询结果集
         *
         * @return 数据库游标 cursor
         */
        public cursor executenative() {
            // 查询表是否存在
            string sql = sqlbuilder.buildquerytableisexistsql(objectclass);
            cursor cursor = executor.rawquery(sql, null);
            if (cursor != null) {
                try {
                    if (cursor.movetonext()) {
                        if (cursor.getint(0) == 0) {
                            return null;
                        }
                    }
                } finally {
                    cursor.close();
                }
            } else {
                return null;
            }
    
            //string sql = sqlbuilder.buildquerysql(tableutil.gettablename(objectclass), columns, wheresection, whereargs, groupby, having, orderby, limit);
            //cursor cursor = db.rawquery(sql, null);
            // 执行查询
            return executor.query(this);
        }
    
        /**
         * 执行查询操作，获取查询结果集
         *
         * @return 查询结果集，空集则查询不到
         * @throws instantiationexception
         * @throws illegalaccessexception
         * @throws nosuchfieldexception
         * @throws parseexception
         */
        public list findall() throws instantiationexception, illegalaccessexception, nosuchfieldexception, parseexception {
            list results = new arraylist<>();
    
            // 执行查询
            cursor cursor = executenative();
            if (cursor != null) {
                try {
                    while (cursor.movetonext()) {
                        t object = objectutil.buildobject(objectclass, cursor);
                        results.add(object);
                    }
                } finally {
                    cursor.close();
                }
            }
            return results;
        }
    
        /**
         * 执行查询操作，获取查询结果集的第一个
         *
         * @return 查询结果集的第一个，null则查询不到
         * @throws instantiationexception
         * @throws illegalaccessexception
         * @throws nosuchfieldexception
         * @throws parseexception
         */
        public t findfirst() throws instantiationexception, illegalaccessexception, nosuchfieldexception, parseexception {
            t result = null;
    
            // 执行查询
            cursor cursor = executenative();
            if (cursor != null) {
                try {
                    if (cursor.movetonext()) {
                        result = objectutil.buildobject(objectclass, cursor);
                    }
                } finally {
                    cursor.close();
                }
            }
            return result;
        }
    }
    

> ps：objectutil用于通过java反射实例化对象，然后对对象进行赋值；

## 3.3 lazydb：orm入口的主类

    
    
    public final class lazydb {
        /**
         * 阻止通过new来实例化lazydb
         * 应该使用create方法来创建lazydb
         */
        private lazydb() {
        }
    
        private sqlitedbexecutor executor;
    
        /**
         * 创建默认配置的数据库
         *
         * @param context 上下文
         */
        public static lazydb create(context context)  {}
    
     ......
    
        /**
         * 创建表
         *
         * @param clazz 类
         */
        public void createtable(class> clazz) throws exception  {}
    
        /**
         * 创建表
         *
         * @param tablename       表名
         * @param idcolumn        id
         * @param iddatatype      id的类型
         * @param isautoincrement 是否自动增长
         * @param columns         其他列名，不包括id
         */
        public void createtable(string tablename, string idcolumn, string iddatatype, boolean isautoincrement, string... columns) throws exception  {}
    
        /**
         * 删除表
         *
         * @param clazz 类
         */
        public void droptable(final class> clazz) throws exception  {}
    
        /**
         * 删除数据库中所有的表
         */
        public void dropalltables() throws exception  {}
    
        /**
         * 查询所有表名
         *
         * @return 所有表名的集合；若没有表，则是空集合
         */
        public list queryalltablenames()  {}
    
        /**
         * 从表中查找出所有字段名
         *
         * @param clazz class
         * @return 字段列表
         * @throws nosuchfieldexception
         * @throws instantiationexception
         * @throws parseexception
         * @throws illegalaccessexception
         */
        public list queryallcolumnsfromtable(class> clazz) throws nosuchfieldexception, instantiationexception, parseexception, illegalaccessexception {}
    
        /**
         * 表是否存在
         *
         * @param clazz 类
         * @return true 表存在，false 表不存在
         */
        public boolean istableexist(class> clazz)  {}
    
        /**
         * 判断对象是否存在数据库中
         *
         * @param object 对象
         * @return true 存在，false 不存在
         * @throws illegalaccessexception
         */
        public boolean isobjectexist(object object) throws illegalaccessexception  {}
    
        /**
         * 插入对象
         *
         * @param object 对象
         */
        public void insert(@nonnull object object) throws exception  {}
    
        /**
         * 插入多个对象数据
         *
         * @param objectlist 对象集合
         * @throws illegalaccessexception
         */
        public void insert(@nonnull final list objectlist) throws exception  {}
    
        /**
         * 更新对象
         *
         * @param object 对象
         * @throws illegalaccessexception
         */
        public void update(@nonnull final object object) throws exception {}
    
        /**
         * 插入或更新对象
         *
         * @param object 对象
         * @throws illegalaccessexception
         */
        public void insertorupdate(@nonnull object object) throws exception  {}
    
        /**
         * 删除对象
         *
         * @param object 对象
         * @throws illegalaccessexception
         */
        public void delete(@nonnull final object object) throws exception  {}
    
        /**
         * 删除多个object集合
         *
         * @param objectlist object集合
         * @throws illegalaccessexception
         */
        public void delete(@nonnull final list objectlist) throws exception  {}
    
        /**
         * 删除数据
         *
         * @param clazz       类
         * @param whereclause 例如：id=?
         * @param whereargs   ?的值
         */
        public void delete(final class> clazz, final string whereclause, final string[] whereargs) throws exception  {}
    
        /**
         * 执行查询操作
         *
         * @param clazz 类
         * @return select操作的构建器
         */
        public  selectbuilder query(class clazz)  {}
    
        /**
         * 通过id查询
         *
         * @param clazz   类
         * @param idvalue idvalue
         * @return object
         * @throws nosuchfieldexception
         * @throws instantiationexception
         * @throws parseexception
         * @throws illegalaccessexception
         */
        public  t querybyid(class clazz, object idvalue) throws exception {}
    

## 4\. 源码与例子的地址

<https://github.com/claymantwinkle/lazydb>

## 5\. java反射优化方案

java反射机制虽然好用，但是为此会牺牲性能，这里有个优化点，可以在取反射时，加一层内存缓存，先查缓存，找不到再取反射。

