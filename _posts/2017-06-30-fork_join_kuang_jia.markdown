---
layout: post
title: "fork/join 框架"
date: 2017-06-30 18:35:00
categories: android
author: kueeniechen
tags: 并发 java
---

* content
{:toc}



**1\. 简介**  
**1.1 什么是fork/join框架**  
        java 5 引入了 executor 和 executorservice 接口，使得 java在并发支持上得到了进一步的提升。 java
<!--more-->
7 更进了一步，fork/join框架是
executorservice接口的一个实现，用来解决可以通过分治法将问题拆分成小任务的问题。在一个任务中，先检查将要解决的问题大小，如果大于一个设定的大小，那就将问题拆分成可以通过框架来执行的小任务，否则直接在任务里解决这个问题，然后根据需要返回任务的结果。下面的图形总结了这个原理：

![](/image/fork_join_kuang_jia/ee186a6b47eb3c90f157a914308d2f15d1390a49eced0a29ad5cb6a424f867e3)  
**1.2 工作窃取算法**  
            fork/join框架和 executor framework主要的区别在于工作窃取算法（work-stealing
algorithm）。假设我们有一个大任务，把任务分成互不依赖的子任务，为了减少线程间的竞争，就把这些子任务放到不同队列中，并为每个队列创建一个单独的线程来执行队列里的任务。但是有的线程干活干得快，与其等着不如去帮其他线程完成任务，通过这种方式，这些线程在运行时拥有所有的优点，进而提升应用程序的性能。  
为了达到这个目标，通过fork/join框架执行的任务有以下**限制**：

  * 任务只能使用fork()和join()操作当作同步机制。如果使用其他同步机制，负责收集子任务结果的工作者线程就不能执行其他任务。
  * 任务不能执行i/o操作
  * 任务不能抛出非运行时异常，必须在代码中处理掉这些异常。

**1.3 fork/join框架的核心类**  
forkjoinpool:这个类实现了executorservice接口和工作窃取算法，它管理工作者线程，并提供任务的状态信息，以及任务的执行信息。

forkjointask：这个类是一个将在forkjoinpool中执行的任务的基类。框架中提供了两个子类：

  * recursiveaction：用于没有返回结果的任务
  * recursivetask：用于有返回结果的任务

**2.实例**

在文档中查找一个词，我们将实现以下两种任务：

  * 一个文档任务，它将遍历文档中的每一行来查找这个词
  * 一个行任务，它将在文档的一部分当中查找这个词

所有这些任务将返回文档或行中所出现这个词的次数。

    
    
    public class documentmock {
    
        private string words[]={"the","hello","goodbye","packet","java","thread","pool","random","class","main"};
    
        public string[][] generatedocument(int numlines, int numwords, string word) {
            int counter = 0;
            string document[][] = new string[numlines][numwords];
            random random = new random();
            for (int i = 0; i < numlines; i++) {
                for (int j = 0; j < numwords; j++) {
                    int index = random.nextint(words.length);
                    document[i][j] = words[index];
                    if (document[i][j].equals(word)) {
                        counter++;
                    }
                }
            }
            system.out.println("documentmock: the word appears " + counter + "times in the document");
            return document;
        }
    }

documenttask类：这个类的任务需要处理由start和end属性决定的文档行，如果行数小于10，那么就每行创建一个linetask对象，然后在任务执行后结束，合计返回的结果，并返回总数。如果任务要处理的行数大于10，那么将任务拆分成两组，并创建documenttask来处理这两组对象。当这些任务执行结束后，合计返回结果。

    
    
    public class documenttask extends recursivetask<integer> {
    
        private string document[][];
        private int start, end;
        private string word;
    
        public documenttask(string[][] document, int start, int end, string word) {
            this.document = document;
            this.start = start;
            this.end = end;
            this.word = word;
        }
    
        @override
        protected integer compute() {
            int result = -1;
            if (end - start < 10) {
                result = processlines(document, start, end, word);
            } else {
                int mid = (start + end) / 2;
                documenttask task1 = new documenttask(document, start, mid, word);
                documenttask task2 = new documenttask(document, mid, end, word);
                invokeall(task1, task2);
                try {
                    result = groupresults(task1.get(), task2.get());
                } catch (interruptedexception | executionexception e) {
                    e.printstacktrace();
                }
            }
            return result;
        }
    
        private integer processlines(string[][] document, int start, int end, string word) {
            list tasks = new arraylist();
            for (int i = start; i < end; i++) {
                linetask task = new linetask(document[i], 0, document[i].length, word);
                tasks.add(task);
            }
            invokeall(tasks);
            int result = 0;
            for (int i = 0; i < tasks.size(); i++) {
                linetask task = tasks.get(i);
                try {
                    result = result + task.get();
                } catch (interruptedexception | executionexception e) {
                    e.printstacktrace();
                }
            }
            return new integer(result);
        }
        private integer groupresults(integer number1, integer number2) {
            integer result;
            result = number1 + number2;
            return result;
        }
    }
    

linetask这个类需要处理文档中一行的某一组词。如果一组词的个数小于100，那么任务将直接在这一组词里搜索特定词，然后返回查找词在这一组词中出现的次数。否则，将任务拆分成两组，并创建两个linetask对象来处理。当结果执行结束后，返回合并结果。

    
    
    public class linetask extends recursivetask<integer> {
        private string line[];
        private int start, end;
        private string word;
    
        public linetask(string[] line, int start, int end, string word) {
            this.line = line;
            this.start = start;
            this.end = end;
            this.word = word;
        }
        @override
        protected integer compute() {
            integer result = null;
            if (end - start < 100) {
                result = count(line, start, end, word);
            } else {
                int mid = (start + end) / 2;
                linetask task1 = new linetask(line, start, mid, word);
                linetask task2 = new linetask(line, mid, end, word);
                invokeall(task1, task2);
                try {
                    result = groupresults(task1.get(), task2.get());
                } catch (interruptedexception | executionexception e) {
                    e.printstacktrace();
                }
            }
            return result;
        }
        private integer count(string[] line, int start, int end, string word) {
            int counter = 0;
            for (int i = start; i < end; i++) {
                if (line[i].equals(word)) {
                    counter++;
                }
            }
            //为了延缓执行，休眠10ms
            try {
                thread.sleep(10);
            } catch (interruptedexception e) {
                e.printstacktrace();
            }
            return counter;
        }
        private integer groupresults(integer number1, integer number2) {
            integer result;
            result = number1 + number2;
            return result;
        }
    }

main函数，通过默认构造器创建了forkjoinpool对象，然后执行documenttask类，来出来一共100行，每行1000字的文档，这个任务将问题拆分成documenttask对象和linetask对象，然后当所有的任务执行完成后，使用原始的任务来获取整个文档中所要查找的词出现的次数，由于任务继承了recursivetask类，因此能够返回结果。

    
    
    public class main {
        public static void main(string[] args) {
            documentmock mock = new documentmock();
            string[][] document = mock.generatedocument(100, 1000, "the");
            documenttask task = new documenttask(document, 0, 100, "the");
            forkjoinpool pool = new forkjoinpool();
            pool.execute(task);
            do {
                system.out.println("***********************************");
                system.out.printf("main parallelism : %d\n", pool.getactivethreadcount());
                system.out.printf("main task count : %d\n", pool.getqueuedtaskcount());
                system.out.printf("main steal count : %d\n", pool.getstealcount());
                system.out.println("***********************************");
    
                try {
                    timeunit.seconds.sleep(1);
                } catch (interruptedexception e) {
                    e.printstacktrace();
                }
            } while (!task.isdone());
    
            pool.shutdown();
            try {
                pool.awaittermination(1, timeunit.days);
            } catch (interruptedexception e) {
                e.printstacktrace();
            }
            try {
                if (task != null) {
                    system.out.printf("main: the word appears %d in the document", task.get());
                }
            } catch (interruptedexception | executionexception e) {
                e.printstacktrace();
            }
        }
    }

 执行结果：

![](/image/fork_join_kuang_jia/fa585145caba008440413cc9d98cbcbf8f8568eddee2791dbaee068c640270f6)

