package net.digitalprimates.persistence.translators.hibernate;

public class TestDataProvider
{
	static Author getAuthor()
	{
		Publisher publisher = new Publisher("Random House","123 Somewhere Lane");
		publisher.setProxyKey(1);
		Author author = new Author("Josh Bloch",30,publisher);
		author.setProxyKey(1);
		author.addBook(new Book(author,"Clean Code",1));
		author.addBook(new Book(author,"Effective Java",2));
		return author;
	}
}
