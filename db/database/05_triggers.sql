CREATE OR REPLACE FUNCTION fn_queue_new_product()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recommendation_queue (product_id, status)
    VALUES (NEW.product_id, 'pending');

    INSERT INTO product_launch_audit (product_id)
    VALUES (NEW.product_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_new_product_queue ON products;
CREATE TRIGGER trg_new_product_queue
AFTER INSERT ON products
FOR EACH ROW
EXECUTE FUNCTION fn_queue_new_product();

