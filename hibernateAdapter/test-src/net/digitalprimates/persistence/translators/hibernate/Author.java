package net.digitalprimates.persistence.translators.hibernate;

import java.util.ArrayList;
import java.util.List;

class Author extends BaseEntity
{
	String name;
	int age;
	List<Book> books;
	Publisher publisher;
	public Author(){}
	public Author(String name, int age, Publisher publisher)
	{
		this(name,age,publisher,null);
	}
	public Author(String name, int age, Publisher publisher,List<Book> books)
	{
		super();
		this.name = name;
		this.age = age;
		this.books = books;
		this.publisher = publisher;
	}
	public String getName()
	{
		return name;
	}
	public void setName(String name)
	{
		this.name = name;
	}
	public int getAge()
	{
		return age;
	}
	public void setAge(int age)
	{
		this.age = age;
	}
	public List<Book> getBooks()
	{
		return books;
	}
	public void setBooks(List<Book> books)
	{
		this.books = books;
	}
	public Publisher getPublisher()
	{
		return publisher;
	}
	public void setPublisher(Publisher publisher)
	{
		this.publisher = publisher;
	}
	public void addBook(Book book)
	{
		if (books == null)
		{
			books = new ArrayList<Book>();
		}
		books.add(book);
	}
	public Book getBook(int i)
	{
		return books.get(i);
	}
}
